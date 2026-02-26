from django.http import JsonResponse, HttpResponse
import os


def api_home(request):
    """
    API Home endpoint - serves Flutter app as homepage
    """
    # Check if request explicitly wants JSON (API clients)
    accept_header = request.META.get('HTTP_ACCEPT', '')
    wants_json = (
        'application/json' in accept_header or
        request.path.endswith('.json') or
        'api' in request.path
    )

    if not wants_json:
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

            # Update base href for proper asset loading
            content = content.replace(
                '<base href="/">',
                '<base href="/static/flutter/">'
            )

            return HttpResponse(content, content_type='text/html')

        except FileNotFoundError:
            # Fallback to simple HTML if Flutter app not found
            return HttpResponse(
                """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SylisStock - Inventory Management</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            max-width: 600px;
            width: 90%;
            text-align: center;
        }

        .logo {
            font-size: 2.5rem;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }

        .title {
            font-size: 1.8rem;
            color: #333;
            margin-bottom: 30px;
        }

        .message {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 25px;
            margin: 20px 0;
            text-align: left;
        }

        .build-button {
            display: inline-block;
            background: linear-gradient(45deg, #02569B, #0175C2);
            color: white;
            padding: 15px 30px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: bold;
            margin: 20px 10px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(2, 86, 155, 0.3);
        }

        .build-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(2, 86, 155, 0.4);
        }

        .footer {
            margin-top: 30px;
            color: #666;
            font-size: 0.8rem;
        }

        @media (max-width: 768px) {
            .container {
                padding: 25px;
                margin: 20px;
            }

            .logo {
                font-size: 2rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">📦 SylisStock</div>
        <h1 class="title">Inventory Management</h1>

        <div class="message">
            <h2 style="color: #333; margin-bottom: 15px;">
                🚀 Flutter App Building...
            </h2>
            <p style="margin-bottom: 15px;">
                The Flutter mobile app is being prepared for deployment.
            </p>
            <p style="margin-bottom: 20px;">
                Please build the Flutter app to see the full interface:
            </p>
            <pre style="background: #f1f3f4; color: #e83e8c; padding: 15px;
                       border-radius: 5px; text-align: left;">
cd mobile_app
flutter build web
            </pre>
            <div style="margin-top: 20px;">
                <a href="/static/flutter/" class="build-button">
                    🔨 Build Flutter App
                </a>
            </div>
        </div>

        <div class="footer">
            <p>🚀 SyliStock - Flutter + Django REST API</p>
            <p>© 2024 SyliStock. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
                """,
                content_type='text/html'
            )
    else:
        # Return JSON response for API consumers
        return JsonResponse({
            'message': 'SyliStock API',
            'version': '1.0.0',
            'endpoints': {
                'inventory': '/inventory/',
                'admin': '/admin/',
                'auth': '/auth/',
                'docs': '/inventory/docs/',
                'flutter_app': '/static/flutter/index.html'
            },
            'status': 'active'
        })
