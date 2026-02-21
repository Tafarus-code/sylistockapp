from django.urls import path
from .views import ProcessScanView

urlpatterns = [
    # Mapping the scan logic to a clean endpoint
    path('process-scan/', ProcessScanView.as_view(), name='process-scan'),
]
