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

# Calculate project root for Railway deployment
# Current file: sylistock/sylistock/urls.py
# Project root: sylistockapp/ (4 levels up)
current_file = os.path.abspath(__file__)
parent_dir = os.path.dirname(current_file)
grandparent_dir = os.path.dirname(parent_dir)
greatgrandparent_dir = os.path.dirname(grandparent_dir)
project_root = os.path.dirname(greatgrandparent_dir)

if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Try different import paths for Railway deployment
try:
    # Try project root first (Railway: sylistockapp/views_home.py)
    from views_home import api_home
except ImportError:
    try:
        # Try sylistockapp directory (local development)
        from sylistockapp.views_home import api_home
    except ImportError:
        # Try relative import as last resort
        from .views_home import api_home

# Import Flutter app view
try:
    from views_flutter import flutter_app
except ImportError:
    try:
        from sylistockapp.views_flutter import flutter_app
    except ImportError:
        from .views_flutter import flutter_app

urlpatterns = [
    path('', api_home, name='api-home'),
    path('app/', flutter_app, name='flutter-app'),
    path('admin/', admin.site.urls),

    # Versioning your API is a Fintech "Must-Have"
    path('inventory/', include('sylistockapp.urls')),

    # Optional: DRF browsable API login (useful for testing in browser)
    path('auth/', include('rest_framework.urls')),
]
