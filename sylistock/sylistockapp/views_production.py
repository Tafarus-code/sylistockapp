from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from django.db.models import Q
from .models import StockItem, MerchantProfile, Product, InventoryLog


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_stock_item(request):
    """
    Add a new stock item
    """
    try:
        merchant_profile = request.user.merchantprofile

        barcode = request.data.get('barcode', '').strip()
        name = request.data.get('name', '').strip()
        quantity = int(request.data.get('quantity', 0))
        price = float(request.data.get('price', 0))
        cost_price = float(request.data.get('cost_price', 0))

        if not barcode or not name:
            return Response(
                {'error': 'Barcode and name are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            # Get or create product
            product, created = Product.objects.get_or_create(
                barcode=barcode,
                defaults={'name': name}
            )

            if not created and product.name != name:
                product.name = name
                product.save()

            # Create stock item
            stock_item = StockItem.objects.create(
                merchant=merchant_profile,
                product=product,
                quantity=quantity,
                cost_price=cost_price,
                sale_price=price,
            )

            # Log the addition
            InventoryLog.objects.create(
                merchant=merchant_profile,
                product=product,
                action='IN',
                quantity_changed=quantity,
                source=request.META.get(
                    'HTTP_X_SCAN_SOURCE', 'MANUAL'
                ),
                device_id=request.META.get(
                    'HTTP_X_DEVICE_ID', 'web'
                ),
            )

        return Response({
            'id': stock_item.pk,
            'barcode': barcode,
            'name': name,
            'quantity': quantity,
            'price': price,
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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def remove_stock_item(request, item_id):
    """
    Remove quantity from stock item
    """
    try:
        merchant_profile = request.user.merchantprofile

        try:
            stock_item = StockItem.objects.get(
                id=item_id,
                merchant=merchant_profile
            )
        except StockItem.DoesNotExist:
            return Response(
                {'error': 'Stock item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        quantity = int(request.data.get('quantity', 0))

        if quantity <= 0:
            return Response(
                {'error': 'Quantity must be positive'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if quantity > stock_item.quantity:
            return Response(
                {'error': 'Insufficient stock'},
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            stock_item.quantity -= quantity
            stock_item.save()

            # Log the removal
            InventoryLog.objects.create(
                merchant=merchant_profile,
                product=stock_item.product,
                action='OUT',
                quantity_changed=-quantity,
                source=request.META.get(
                    'HTTP_X_SCAN_SOURCE', 'MANUAL'
                ),
                device_id=request.META.get(
                    'HTTP_X_DEVICE_ID', 'web'
                ),
            )

        return Response({
            'id': stock_item.pk,
            'remaining_quantity': stock_item.quantity,
            'removed_quantity': quantity,
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


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_stock_item(request, item_id):
    """
    Update stock item details
    """
    try:
        merchant_profile = request.user.merchantprofile

        try:
            stock_item = StockItem.objects.get(
                id=item_id,
                merchant=merchant_profile
            )
        except StockItem.DoesNotExist:
            return Response(
                {'error': 'Stock item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        quantity = request.data.get('quantity')
        price = request.data.get('price')

        with transaction.atomic():
            if quantity is not None:
                quantity = int(quantity)
                old_quantity = stock_item.quantity
                stock_item.quantity = quantity

                # Log the change
                InventoryLog.objects.create(
                    merchant=merchant_profile,
                    product=stock_item.product,
                    action='ADJ',
                    quantity_changed=quantity - old_quantity,
                    source=request.META.get(
                        'HTTP_X_SCAN_SOURCE', 'MANUAL'
                    ),
                    device_id=request.META.get(
                        'HTTP_X_DEVICE_ID', 'web'
                    ),
                )

            if price is not None:
                stock_item.sale_price = float(price)

            stock_item.save()

        return Response({
            'id': stock_item.pk,
            'quantity': stock_item.quantity,
            'price': stock_item.sale_price,
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
def get_stock_items(request):
    """
    Get all stock items for merchant
    """
    try:
        merchant_profile = request.user.merchantprofile

        search = request.GET.get('search', '')
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))

        queryset = StockItem.objects.filter(merchant=merchant_profile)

        if search:
            queryset = queryset.filter(
                Q(product__barcode__icontains=search) |
                Q(product__name__icontains=search)
            )

        queryset = queryset.select_related('product').order_by('-pk')

        # Pagination
        start = (page - 1) * page_size
        end = start + page_size
        items = queryset[start:end]

        items_data = []
        for item in items:
            items_data.append({
                'id': item.pk,
                'barcode': item.product.barcode,
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.sale_price,
                'last_updated': item.updated_at,
            })

        return Response({
            'items': items_data,
            'page': page,
            'page_size': page_size,
            'total': queryset.count(),
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
def inventory_history(request):
    """
    Get inventory change history
    """
    try:
        merchant_profile = request.user.merchantprofile
        logs = InventoryLog.objects.filter(
            merchant=merchant_profile
        ).select_related('product').order_by('-timestamp')[:100]

        history_data = []
        for log in logs:
            history_data.append({
                'id': log.pk,
                'product_name': log.product.name,
                'barcode': log.product.barcode,
                'action': log.action,
                'quantity_changed': log.quantity_changed,
                'device_id': log.device_id,
                'timestamp': log.timestamp,
            })

        return Response({
            'history': history_data,
            'count': len(history_data),
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
