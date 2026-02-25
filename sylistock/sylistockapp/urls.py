from django.urls import path
from .views_production import (
    add_stock_item,
    remove_stock_item,
    update_stock_item,
    get_stock_items,
)
from .views_alerts import (
    low_stock_alerts,
    set_stock_alert_threshold,
)
from .views_reporting import (
    sales_report,
    merchant_performance,
)
from .views_stock_management import (
    search_items,
    get_item_details,
)
from .views_bulk_operations import (
    bulk_import_inventory,
    export_inventory,
    bulk_update_inventory,
)

urlpatterns = [
    # Stock management
    path('items/', get_stock_items, name='stock-items'),
    path('items/add/', add_stock_item, name='add-stock-item'),
    path('items/update/<int:item_id>/', update_stock_item, name='update-stock-item'),
    path('items/remove/<int:item_id>/', remove_stock_item, name='remove-stock-item'),
    path('items/search/', search_items, name='search-items'),
    path('items/<int:item_id>/', get_item_details, name='item-details'),
    
    # Alerts
    path('alerts/low-stock/', low_stock_alerts, name='low-stock-alerts'),
    path('alerts/threshold/', set_stock_alert_threshold, name='set-alert-threshold'),
    
    # Reports
    path('reports/sales/', sales_report, name='sales-report'),
    path('reports/performance/',
         merchant_performance,
         name='performance-report'),

    # Bulk operations
    path('bulk/import/', bulk_import_inventory, name='bulk-import'),
    path('bulk/export/', export_inventory, name='bulk-export'),
    path('bulk/update/', bulk_update_inventory, name='bulk-update'),
]
