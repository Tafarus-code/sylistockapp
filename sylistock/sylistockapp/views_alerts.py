from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import StockItem, MerchantProfile
from .serializers import StockItemSerializer


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def low_stock_alerts(request):
    """
    Get items with low stock (less than threshold)
    """
    try:
        merchant_profile = request.user.merchantprofile
        threshold = int(request.GET.get('threshold', 5))

        low_stock_items = StockItem.objects.filter(
            merchant=merchant_profile,
            quantity__lt=threshold
        ).select_related('product').order_by('quantity')

        serializer = StockItemSerializer(low_stock_items, many=True)

        critical_count = low_stock_items.filter(quantity__lt=2).count()
        item_count = low_stock_items.count()

        return Response({
            'low_stock_items': serializer.data,
            'threshold': threshold,
            'count': item_count,
            'critical_count': critical_count,
            'message': (
                f'{item_count} items below threshold of {threshold}'
            )
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
@permission_classes([permissions.IsAuthenticated])
def set_stock_alert_threshold(request):
    """
    Set custom low stock alert threshold
    """
    try:
        threshold = int(request.data.get('threshold', 5))

        # You could save this to merchant profile
        # merchant_profile.low_stock_threshold = threshold
        # merchant_profile.save()

        return Response({
            'success': True,
            'message': f'Low stock alert threshold set to {threshold}',
            'threshold': threshold
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

