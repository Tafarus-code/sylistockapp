from django.http import JsonResponse


def api_home(request):
    """
    API Home endpoint - provides basic API information
    """
    return JsonResponse({
        'message': 'SylisStock API',
        'version': '1.0.0',
        'endpoints': {
            'inventory': '/inventory/',
            'admin': '/admin/',
            'auth': '/auth/',
            'docs': '/inventory/docs/'
        },
        'status': 'active'
    })
