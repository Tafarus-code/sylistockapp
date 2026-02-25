from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils import timezone
from .models import Product, StockItem, InventoryLog, MerchantProfile
import csv
import io


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def bulk_import_inventory(request):
    """
    Import inventory from CSV file
    """
    try:
        merchant_profile = request.user.merchantprofile

        if 'file' not in request.FILES:
            return Response(
                {'error': 'No file provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        csv_file = request.FILES['file']
        if not csv_file.name.endswith('.csv'):
            return Response(
                {'error': 'File must be a CSV file'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Read and process CSV
        decoded_file = csv_file.read().decode('utf-8').splitlines()
        reader = csv.DictReader(decoded_file)

        imported_count = 0
        skipped_count = 0
        errors = []

        with transaction.atomic():
            for row_num, row in enumerate(reader, 1):
                try:
                    barcode = row.get('barcode', '').strip()
                    name = row.get('name', '').strip()
                    quantity = int(row.get('quantity', 0))
                    cost_price = (
                        float(row.get('cost_price', 0))
                        if row.get('cost_price') else None
                    )
                    sale_price = (
                        float(row.get('sale_price', 0))
                        if row.get('sale_price') else None
                    )

                    if not barcode or not name:
                        errors.append(
                            f'Row {row_num}: Missing barcode or name'
                        )
                        skipped_count += 1
                        continue

                    # Get or create product
                    product, created = Product.objects.get_or_create(
                        barcode=barcode,
                        defaults={
                            'name': name,
                            'description': row.get('description', ''),
                        }
                    )

                    # Create stock item
                    StockItem.objects.create(
                        merchant=merchant_profile,
                        product=product,
                        quantity=quantity,
                        cost_price=cost_price,
                        sale_price=sale_price
                    )

                    # Log the import
                    InventoryLog.objects.create(
                        merchant=merchant_profile,
                        product=product,
                        action='IN',
                        quantity_changed=quantity,
                        source='BULK_IMPORT',
                        device_id='mobile_app',
                        reason=f'CSV import row {row_num}'
                    )

                    imported_count += 1

                except Exception as e:
                    errors.append(f'Row {row_num}: {str(e)}')
                    skipped_count += 1

        return Response({
            'success': True,
            'message': (
                f'Imported {imported_count} items, '
                f'skipped {skipped_count}'
            ),
            'imported_count': imported_count,
            'skipped_count': skipped_count,
            'errors': errors,
        })

    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def export_inventory(request):
    """
    Export inventory to CSV file
    """
    try:
        merchant_profile = request.user.merchantprofile
        format_type = request.GET.get('format', 'csv')

        # Get inventory items
        stock_items = StockItem.objects.filter(
            merchant=merchant_profile
        ).select_related('product').order_by('product__name')

        if format_type == 'csv':
            response = Response(content_type='text/csv')

            # Create CSV content
            output = io.StringIO()
            writer = csv.writer(output)

            # Header
            writer.writerow([
                'Barcode', 'Name', 'Description', 'Quantity',
                'Cost Price', 'Sale Price', 'Total Value'
            ])

            # Data rows
            for item in stock_items:
                unit_price = float(
                    item.sale_price or item.cost_price or 0
                )
                total_value = unit_price * item.quantity
                writer.writerow([
                    item.product.barcode,
                    item.product.name,
                    item.product.description or '',
                    item.quantity,
                    float(item.cost_price or 0),
                    float(item.sale_price or 0),
                    total_value,
                ])

            response.content = output.getvalue()
            date_str = timezone.now().date()
            response['Content-Disposition'] = (
                f'attachment; filename="inventory_export_{date_str}.csv"'
            )
            return response

        else:
            return Response(
                {'error': 'Unsupported format. Use CSV'},
                status=status.HTTP_400_BAD_REQUEST
            )

    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def bulk_update_inventory(request):
    """
    Bulk update inventory items
    """
    try:
        merchant_profile = request.user.merchantprofile
        updates = request.data.get('updates', [])

        updated_count = 0
        errors = []

        with transaction.atomic():
            for update in updates:
                try:
                    item_id = update.get('item_id')
                    quantity = int(update.get('quantity', 0))
                    cost_price = (
                        float(update.get('cost_price', 0))
                        if update.get('cost_price') else None
                    )
                    sale_price = (
                        float(update.get('sale_price', 0))
                        if update.get('sale_price') else None
                    )

                    stock_item = get_object_or_404(
                        StockItem.objects.filter(
                            id=item_id,
                            merchant=merchant_profile
                        )
                    )

                    old_quantity = stock_item.quantity
                    stock_item.quantity = quantity
                    if cost_price is not None:
                        stock_item.cost_price = cost_price
                    if sale_price is not None:
                        stock_item.sale_price = sale_price
                    stock_item.save()

                    # Log the update
                    qty_changed = quantity - old_quantity
                    reason = (
                        f'Bulk update: quantity '
                        f'{old_quantity}->{quantity}'
                    )
                    InventoryLog.objects.create(
                        merchant=merchant_profile,
                        product=stock_item.product,
                        action='ADJ',
                        quantity_changed=qty_changed,
                        source='BULK_UPDATE',
                        device_id='mobile_app',
                        reason=reason
                    )

                    updated_count += 1

                except Exception as e:
                    errors.append(f'Item {item_id}: {str(e)}')

        return Response({
            'success': True,
            'message': f'Updated {updated_count} items',
            'updated_count': updated_count,
            'errors': errors,
        })

    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


