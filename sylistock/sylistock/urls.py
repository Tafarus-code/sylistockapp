"""
URL configuration for sylistock project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
import sys
import os

# Add project root to Python path for Railway deployment
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

try:
    from views_home import api_home
except ImportError:
    # Fallback to local relative import
    from .views_home import api_home

urlpatterns = [
    path('', api_home, name='api-home'),
    path('admin/', admin.site.urls),

    # Versioning your API is a Fintech "Must-Have"
    path('inventory/', include('sylistockapp.urls')),

    # Optional: DRF browsable API login (useful for testing in browser)
    path('auth/', include('rest_framework.urls')),
]
