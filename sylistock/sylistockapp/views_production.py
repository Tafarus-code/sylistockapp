from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils import timezone
from .models import Product, StockItem, InventoryLog, MerchantProfile
from .serializers import (
    ProductSerializer, StockItemSerializer,
    InventoryLogSerializer, ScanSerializer
)


@api_view(['GET', 'POST'])
@permission_classes([permissions.IsAuthenticated])
def inventory_list_create(request):
    """
    List all inventory items or create new item
    """
    if request.method == 'GET':
        # Get merchant's inventory
        try:
            merchant_profile = request.user.merchantprofile
            stock_items = StockItem.objects.filter(
                merchant=merchant_profile
            ).select_related('product').order_by('-id')

            serializer = StockItemSerializer(stock_items, many=True)
            return Response(serializer.data)
        except MerchantProfile.DoesNotExist:
            return Response(
                {'error': 'Merchant profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    elif request.method == 'POST':
        # Create new inventory item
        try:
            merchant_profile = request.user.merchantprofile
            serializer = StockItemSerializer(data=request.data)

            if serializer.is_valid():
                # Get or create product
                product_data = serializer.validated_data['product']
                barcode = product_data['barcode']
                product, created = Product.objects.get_or_create(
                    barcode=barcode,
                    defaults={
                        'name': product_data['name'],
                        'description': product_data.get('description', '')
                    }
                )

                # Create stock item
                stock_item = serializer.save(
                    merchant=merchant_profile,
                    product=product
                )

                # Log the addition
                InventoryLog.objects.create(
                    merchant=merchant_profile,
                    product=product,
                    action='IN',
                    quantity_changed=stock_item.quantity,
                    source='MANUAL',
                    device_id='mobile_app'
                )

                response_serializer = StockItemSerializer(stock_item)
                return Response(
                    response_serializer.data,
                    status=status.HTTP_201_CREATED
                )
            else:
                return Response(
                    serializer.errors,
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


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([permissions.IsAuthenticated])
def inventory_detail_update_delete(request, pk):
    """
    Retrieve, update or delete inventory item
    """
    try:
        merchant_profile = request.user.merchantprofile
        stock_item = get_object_or_404(
            StockItem.objects.filter(pk=pk, merchant=merchant_profile)
        )
    except StockItem.DoesNotExist:
        return Response(
            {'error': 'Inventory item not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except MerchantProfile.DoesNotExist:
        return Response(
            {'error': 'Merchant profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    if request.method == 'GET':
        serializer = StockItemSerializer(stock_item)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = StockItemSerializer(
            stock_item,
            data=request.data,
            partial=True
        )
        if serializer.is_valid():
            old_quantity = stock_item.quantity
            updated_item = serializer.save()

            # Log the change if quantity changed
            if old_quantity != updated_item.quantity:
                action = (
                    'ADJ' if updated_item.quantity < old_quantity else 'IN'
                )
                quantity_change = updated_item.quantity - old_quantity

                InventoryLog.objects.create(
                    merchant=merchant_profile,
                    product=stock_item.product,
                    action=action,
                    quantity_changed=quantity_change,
                    source='MANUAL',
                    device_id='mobile_app'
                )

            response_serializer = StockItemSerializer(updated_item)
            return Response(response_serializer.data)
        else:
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )

    elif request.method == 'DELETE':
        # Log the removal
        InventoryLog.objects.create(
            merchant=merchant_profile,
            product=stock_item.product,
            action='OUT',
            quantity_changed=-stock_item.quantity,
            source='MANUAL',
            device_id='mobile_app'
        )

        stock_item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def process_scan(request):
    """
    Process barcode scan from Zebra scanner or phone camera
    """
    try:
        merchant_profile = request.user.merchantprofile
        serializer = ScanSerializer(data=request.data)

        if serializer.is_valid():
            barcode = serializer.validated_data['barcode']
            action = serializer.validated_data['action']
            source = serializer.validated_data['source']
            device_id = serializer.validated_data.get(
                'device_id', 'unknown'
            )

            # Get or create product
            product, created = Product.objects.get_or_create(
                barcode=barcode,
                defaults={
                    'name': f'Product {barcode}',
                    'description': f'Auto-created from scan {barcode}'
                }
            )

            with transaction.atomic():
                # Get or create stock item
                stock_item, created = StockItem.objects.get_or_create(
                    merchant=merchant_profile,
                    product=product,
                    defaults={'quantity': 0}
                )

                # Update quantity based on action
                if action == 'IN':
                    stock_item.quantity += 1
                    message = f'Stocked in: {barcode}'
                elif action == 'OUT':
                    if stock_item.quantity >= 1:
                        stock_item.quantity -= 1
                        message = f'Sold: {barcode}'
                    else:
                        return Response(
                            {'error': 'Insufficient stock for this item'},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                else:
                    return Response(
                        {'error': 'Invalid action'},
                        status=status.HTTP_400_BAD_REQUEST
                    )

                stock_item.save()

                # Log the scan
                qty_change = 1 if action == 'IN' else -1
                InventoryLog.objects.create(
                    merchant=merchant_profile,
                    product=product,
                    action=action,
                    quantity_changed=qty_change,
                    source=source,
                    device_id=device_id,
                    timestamp=timezone.now()
                )

                return Response({
                    'message': message,
                    'product': ProductSerializer(product).data,
                    'stock_item': StockItemSerializer(stock_item).data,
                    'current_quantity': stock_item.quantity
                })
        else:
            return Response(
                serializer.errors,
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


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def inventory_history(request):
    """
    Get inventory change history
    """
    try:
        merchant_profile = request.user.merchantprofile
        logs = InventoryLog.objects.filter(
            merchant=merchant_profile
        ).select_related('product').order_by('-timestamp')[:100]

        serializer = InventoryLogSerializer(logs, many=True)
        return Response(serializer.data)

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
def low_stock_alerts(request):
    """
    Get items with low stock (less than 5)
    """
    try:
        merchant_profile = request.user.merchantprofile
        low_stock_items = StockItem.objects.filter(
            merchant=merchant_profile,
            quantity__lt=5
        ).select_related('product')

        serializer = StockItemSerializer(low_stock_items, many=True)
        return Response({
            'low_stock_items': serializer.data,
            'count': low_stock_items.count()
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


