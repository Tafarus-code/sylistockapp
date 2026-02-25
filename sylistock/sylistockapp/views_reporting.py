from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Q, Sum, Count
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import datetime, timedelta
from .models import StockItem, InventoryLog, MerchantProfile
from .serializers import StockItemSerializer, InventoryLogSerializer
from decimal import Decimal

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def sales_report(request):
    """
    Generate sales report from inventory logs
    """
    try:
        merchant_profile = request.user.merchantprofile
        days = int(request.GET.get('days', 30))
        start_date = timezone.now() - timedelta(days=days)
        
        # Get sales (OUT actions) from inventory logs
        sales_logs = InventoryLog.objects.filter(
            merchant=merchant_profile,
            action='OUT',
            timestamp__gte=start_date
        ).select_related('product')
        
        # Calculate total sales
        total_sales = 0
        sales_data = []
        
        for log in sales_logs:
            # This is a simplified calculation - in real app, you'd track actual sales
            quantity = abs(log.quantity_changed)
            total_sales += quantity
            
            sales_data.append({
                'date': log.timestamp.date(),
                'product_name': log.product.name,
                'barcode': log.product.barcode,
                'quantity': quantity,
                'device_id': log.device_id,
            })
        
        return Response({
            'total_sales': total_sales,
            'sales_count': len(sales_data),
            'period_days': days,
            'sales_data': sales_data,
            'start_date': start_date.date(),
            'end_date': timezone.now().date(),
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
def inventory_value_report(request):
    """
    Generate inventory value report
    """
    try:
        merchant_profile = request.user.merchantprofile
        
        # Calculate total inventory value
        inventory_items = StockItem.objects.filter(merchant=merchant_profile).select_related('product')
        
        total_items = inventory_items.count()
        total_quantity = inventory_items.aggregate(Sum('quantity'))['quantity__sum'] or 0
        
        # Calculate total value (using sale_price as current value)
        total_value = Decimal('0')
        inventory_data = []
        
        for item in inventory_items:
            item_value = (item.sale_price or item.cost_price or Decimal('0')) * item.quantity
            total_value += item_value
            
            inventory_data.append({
                'name': item.product.name,
                'barcode': item.product.barcode,
                'quantity': item.quantity,
                'unit_price': float(item.sale_price or item.cost_price or 0),
                'total_value': float(item_value),
            })
        
        return Response({
            'summary': {
                'total_items': total_items,
                'total_quantity': int(total_quantity),
                'total_value': float(total_value),
            },
            'inventory_data': inventory_data,
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
def merchant_performance(request):
    """
    Generate merchant performance metrics
    """
    try:
        merchant_profile = request.user.merchantprofile
        
        # Get inventory logs for the last 30 days
        start_date = timezone.now() - timedelta(days=30)
        logs = InventoryLog.objects.filter(
            merchant=merchant_profile,
            timestamp__gte=start_date
        )
        
        # Calculate metrics
        total_scans = logs.filter(action__in=['IN', 'OUT']).count()
        manual_entries = logs.filter(source='MANUAL').count()
        zebra_scans = logs.filter(source='ZEBRA').count()
        phone_scans = logs.filter(source='PHONE').count()
        
        return Response({
            'period_days': 30,
            'total_scans': total_scans,
            'manual_entries': manual_entries,
            'zebra_scans': zebra_scans,
            'phone_scans': phone_scans,
            'scan_sources': {
                'ZEBRA': zebra_scans,
                'PHONE': phone_scans,
                'MANUAL': manual_entries,
            },
            'most_active_source': max([
                ('ZEBRA', zebra_scans),
                ('PHONE', phone_scans),
                ('MANUAL', manual_entries),
            ], key=lambda x: x[1])[1],
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
