from django.urls import path
from .views import ProcessScanView, InventoryListView, InventoryDetailView

urlpatterns = [
    # CRUD endpoints for Flutter app
    path('', InventoryListView.as_view(), name='inventory-list'),
    path('<int:pk>/', InventoryDetailView.as_view(), name='inventory-detail'),
    
    # Original scan processing endpoint
    path('process-scan/', ProcessScanView.as_view(), name='process-scan'),
]
