from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from datetime import timedelta
from .models import MerchantProfile, InventoryLog, StockItem


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sales_report(request):
    """
    Get sales report for specified period
    """
    try:
        merchant_profile = request.user.merchantprofile
        days = int(request.GET.get('days', 7))
        start_date = timezone.now() - timedelta(days=days)

        # Get sales (OUT actions) from inventory logs
        sales_logs = InventoryLog.objects.filter(
            merchant=merchant_profile,
            action='OUT',
            timestamp__gte=start_date
        ).select_related('product')

        # Build price lookup from StockItems
        stock_prices = dict(
            StockItem.objects.filter(
                merchant=merchant_profile
            ).values_list('product_id', 'sale_price')
        )

        # Calculate total sales and revenue
        total_sales = 0
        total_revenue = 0
        sales_data = []
        device_counts = {}

        for log in sales_logs:
            quantity = abs(log.quantity_changed)
            total_sales += quantity

            # Calculate revenue
            unit_price = float(
                stock_prices.get(log.product_id, 0)
            )
            revenue = unit_price * quantity
            total_revenue += revenue

            # Count device usage
            device_id = log.device_id or 'unknown'
            device_counts[device_id] = (
                device_counts.get(device_id, 0) + 1
            )

            sales_data.append({
                'date': log.timestamp.date(),
                'product_name': log.product.name,
                'barcode': log.product.barcode,
                'quantity': quantity,
                'unit_price': unit_price,
                'revenue': revenue,
                'device_id': log.device_id,
            })

        # Find most active device
        most_active = (
            max(device_counts.items(), key=lambda x: x[1])[0]
            if device_counts else 'none'
        )

        return Response({
            'total_sales': total_sales,
            'total_revenue': total_revenue,
            'sales_count': len(sales_data),
            'period_days': days,
            'sales_data': sales_data,
            'start_date': start_date.date(),
            'most_active_source': most_active,
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
def merchant_performance(request):
    """
    Get merchant performance metrics
    """
    try:
        merchant_profile = request.user.merchantprofile

        # Get basic metrics
        total_products = merchant_profile.stockitem_set.count()
        low_stock_count = merchant_profile.stockitem_set.filter(
            quantity__lte=merchant_profile.alert_threshold
        ).count()

        # Get recent activity
        recent_logs = InventoryLog.objects.filter(
            merchant=merchant_profile,
            timestamp__gte=timezone.now() - timedelta(days=7)
        ).count()

        return Response({
            'total_products': total_products,
            'low_stock_count': low_stock_count,
            'recent_activity': recent_logs,
            'health_score': max(0, 100 - (low_stock_count * 10)),
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
