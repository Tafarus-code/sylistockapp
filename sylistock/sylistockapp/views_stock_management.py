from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import StockItem, InventoryLog, MerchantProfile
from .serializers import StockItemSerializer


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def update_stock_quantity(request):
    """
    Add or subtract stock quantity
    """
    try:
        merchant_profile = request.user.merchantprofile
        item_id = request.data.get('item_id')
        quantity_change = int(request.data.get('quantity_change', 0))
        reason = request.data.get('reason', 'Manual adjustment')

        stock_item = get_object_or_404(
            StockItem.objects.filter(
                id=item_id,
                merchant=merchant_profile
            )
        )

        old_quantity = stock_item.quantity
        new_quantity = old_quantity + quantity_change

        if new_quantity < 0:
            return Response(
                {'error': 'Cannot have negative quantity'},
                status=status.HTTP_400_BAD_REQUEST
            )

        stock_item.quantity = new_quantity
        stock_item.save()

        # Log the change
        action = 'ADJ' if quantity_change < 0 else 'IN'
        InventoryLog.objects.create(
            merchant=merchant_profile,
            product=stock_item.product,
            action=action,
            quantity_changed=quantity_change,
            source='MANUAL',
            device_id='mobile_app',
            reason=reason
        )

        return Response({
            'success': True,
            'message': (
                f'Stock updated from {old_quantity} to {new_quantity}'
            ),
            'item': StockItemSerializer(stock_item).data
        })

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
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def bulk_update_prices(request):
    """
    Update prices for multiple items
    """
    try:
        merchant_profile = request.user.merchantprofile
        price_updates = request.data.get('price_updates', [])

        updated_items = []
        for update in price_updates:
            item_id = update.get('item_id')
            cost_price = update.get('cost_price')
            sale_price = update.get('sale_price')

            stock_item = get_object_or_404(
                StockItem.objects.filter(
                    id=item_id,
                    merchant=merchant_profile
                )
            )

            if cost_price is not None:
                stock_item.cost_price = cost_price
            if sale_price is not None:
                stock_item.sale_price = sale_price

            stock_item.save()
            updated_items.append(stock_item)

            # Log price updates
            reason = (
                f'Price updated: cost={cost_price}, sale={sale_price}'
            )
            InventoryLog.objects.create(
                merchant=merchant_profile,
                product=stock_item.product,
                action='ADJ',
                quantity_changed=0,
                source='MANUAL',
                device_id='mobile_app',
                reason=reason
            )

        message = f'Updated {len(updated_items)} item prices'
        return Response({
            'success': True,
            'message': message,
            'updated_items': StockItemSerializer(
                updated_items,
                many=True
            ).data
        })

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

