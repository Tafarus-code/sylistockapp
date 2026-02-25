from django.urls import path
from .views import (
    ProcessScanView, InventoryListView, InventoryDetailView,
)
from .views_production import (
    inventory_list_create, inventory_detail_update_delete,
    process_scan, inventory_history, low_stock_alerts,
)
from .views_stock_management import (
    update_stock_quantity, bulk_update_prices,
)
from .views_reporting import (
    sales_report, inventory_value_report, merchant_performance,
)
from .views_bulk_operations import (
    bulk_import_inventory, export_inventory, bulk_update_inventory,
)

urlpatterns = [
    # Core CRUD operations
    path('', inventory_list_create, name='inventory-list'),
    path('<int:pk>/', inventory_detail_update_delete, name='inventory-detail'),
    
    # Scanner operations
    path('process-scan/', process_scan, name='process-scan'),
    
    # Stock management
    path('stock/update/', update_stock_quantity, name='stock-update'),
    path('stock/bulk-update/', bulk_update_prices, name='stock-bulk-update'),
    
    # Alerts and notifications
    path('alerts/low-stock/', low_stock_alerts, name='low-stock-alerts'),
    path('alerts/set-threshold/', set_stock_alert_threshold, name='set-stock-threshold'),
    
    # Reporting and analytics
    path('reports/sales/', sales_report, name='sales-report'),
    path('reports/inventory-value/', inventory_value_report, name='inventory-value-report'),
    path('reports/performance/', merchant_performance, name='performance-report'),
    
    # Bulk operations
    path('bulk/import/', bulk_import_inventory, name='bulk-import'),
    path('bulk/export/', export_inventory, name='bulk-export'),
    path('bulk/update/', bulk_update_inventory, name='bulk-update'),
]
