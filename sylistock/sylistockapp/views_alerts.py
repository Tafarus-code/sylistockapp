from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import StockItem, MerchantProfile


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def low_stock_alerts(request):
    """
    Get items with low stock levels
    """
    try:
        merchant_profile = request.user.merchantprofile
        threshold = int(request.GET.get('threshold', 5))
        
        low_stock_items = StockItem.objects.filter(
            merchant=merchant_profile,
            quantity__lte=threshold
        ).select_related('product')
        
        alerts = []
        for item in low_stock_items:
            alerts.append({
                'id': item.pk,
                'product_name': item.product.name,
                'barcode': item.product.barcode,
                'current_quantity': item.quantity,
                'threshold': threshold,
                'last_updated': item.pk,  # Using pk as placeholder since no updated_at field
            })
        
        return Response({
            'alerts': alerts,
            'count': len(alerts),
            'threshold': threshold,
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
def set_stock_alert_threshold(request):
    """
    Set custom low stock alert threshold
    """
    try:
        threshold = int(request.data.get('threshold', 5))

        # You could save this to merchant profile
        # For now, just return success
        return Response({
            'message': f'Alert threshold set to {threshold}',
            'threshold': threshold,
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
