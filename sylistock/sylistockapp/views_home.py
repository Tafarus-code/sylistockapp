from django.http import JsonResponse, HttpResponse
import os


def api_info(request):
    """
    API info endpoint - returns JSON API information
    """
    return JsonResponse({
        'message': 'SyliStock API',
        'version': '1.0.0',
        'endpoints': {
            'inventory': '/inventory/',
            'admin': '/admin/',
            'auth': '/auth/',
            'docs': '/inventory/docs/',
            'flutter_app': '/'
        },
        'status': 'active'
    })


def api_home(request):
    """
    Homepage - serves Flutter app
    """
    # Serve Flutter app as homepage
    flutter_index_path = os.path.join(
        os.path.dirname(__file__),
        'static',
        'flutter',
        'index.html'
    )

    try:
        with open(flutter_index_path, 'r', encoding='utf-8') as f:
            content = f.read()

        return HttpResponse(content, content_type='text/html')

    except FileNotFoundError:
        # Fallback HTML if Flutter app not found
        return HttpResponse(
            """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SylisStock - Flutter App Not Found</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            margin: 0;
            padding: 40px;
            text-align: center;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 40px;
            max-width: 600px;
            margin: 0 auto;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .error { color: #e74c3c; }
        .command {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            text-align: left;
            font-family: monospace;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📦 SylisStock</h1>
        <p class="error">Flutter app not found</p>
        <p>Please build the Flutter app first:</p>
        <div class="command">
            cd mobile_app<br>
            flutter build web<br>
            cd ..<br>
            xcopy "mobile_app\\build\\web" "sylistock\\sylistockapp\\static\\flutter"\n            /E /Y /Q
        </div>
    </div>
</body>
</html>
            """,
            content_type='text/html'
        )
