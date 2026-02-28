from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
import csv
import io
from .models import StockItem, MerchantProfile, Product


@api_view(['POST'])
@permission_classes([IsAuthenticated])
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
                {'error': 'File must be a CSV'},
                status=status.HTTP_400_BAD_REQUEST
            )

        decoded_file = csv_file.read().decode('utf-8')
        io_string = io.StringIO(decoded_file)
        reader = csv.DictReader(io_string)

        imported_count = 0
        errors = []

        with transaction.atomic():
            for row_num, row in enumerate(reader, 1):
                try:
                    barcode = row.get('barcode', '').strip()
                    name = row.get('name', '').strip()
                    quantity = int(row.get('quantity', 0))
                    price = float(row.get('price', 0))
                    cost_price = float(row.get('cost_price', 0))

                    if not barcode or not name:
                        error_msg = f'Row {row_num}: Missing barcode or name'
                        errors.append(error_msg)
                        continue

                    # Get or create product
                    product, created = Product.objects.get_or_create(
                        barcode=barcode,
                        defaults={'name': name}
                    )

                    if not created and product.name != name:
                        product.name = name
                        product.save()

                    # Create or update stock item
                    stock_item, created = StockItem.objects.get_or_create(
                        merchant=merchant_profile,
                        product=product,
                        defaults={
                            'quantity': quantity,
                            'cost_price': cost_price,
                            'sale_price': price,
                        }
                    )

                    if not created:
                        stock_item.quantity = quantity
                        stock_item.cost_price = cost_price
                        stock_item.sale_price = price
                        stock_item.save()

                    imported_count += 1

                except Exception as e:
                    errors.append(f'Row {row_num}: {str(e)}')

        return Response({
            'imported': imported_count,
            'errors': errors,
            'total_rows': row_num,
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
@permission_classes([IsAuthenticated])
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
        ).select_related('product')

        if format_type == 'csv':
            response = Response(content_type='text/csv')
            disposition = 'attachment; filename=inventory.csv'
            response['Content-Disposition'] = disposition

            writer = csv.writer(response)
            writer.writerow(['Barcode', 'Name', 'Quantity', 'Price'])

            for item in stock_items:
                writer.writerow([
                    item.product.barcode,
                    item.product.name,
                    item.quantity,
                    item.sale_price,
                ])

            return response

        else:
            return Response(
                {'error': 'Unsupported format'},
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
@permission_classes([IsAuthenticated])
def bulk_update_inventory(request):
    """
    Bulk update inventory items
    """
    try:
        merchant_profile = request.user.merchantprofile
        updates = request.data.get('updates', [])

        if not updates:
            return Response(
                {'error': 'No updates provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        updated_count = 0
        errors = []

        with transaction.atomic():
            for idx, update in enumerate(updates):
                try:
                    item_id = update.get('id')
                    quantity = update.get('quantity')
                    price = update.get('price')

                    if not item_id:
                        errors.append(f'Update {idx}: Missing item ID')
                        continue

                    try:
                        stock_item = StockItem.objects.get(
                            id=item_id,
                            merchant=merchant_profile
                        )

                        if quantity is not None:
                            stock_item.quantity = quantity

                        if price is not None:
                            stock_item.sale_price = price

                        stock_item.save()
                        updated_count += 1

                    except StockItem.DoesNotExist:
                        errors.append(f'Update {idx}: Item not found')

                except Exception as e:
                    errors.append(f'Update {idx}: {str(e)}')

        return Response({
            'updated': updated_count,
            'errors': errors,
            'total_updates': len(updates),
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
