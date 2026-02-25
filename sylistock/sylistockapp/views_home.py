from django.http import JsonResponse, HttpResponse
from django.template.loader import render_to_string


def api_home(request):
    """
    API Home endpoint - provides API information with full UI
    """
    
    # Check if request wants HTML or JSON
    if 'text/html' in request.META.get('HTTP_ACCEPT', ''):
        # Return HTML UI
        template_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SylisStock API</title>
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
        
        .api-info {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 25px;
            margin: 20px 0;
            text-align: left;
        }
        
        .endpoint-list {
            list-style: none;
            padding: 0;
        }
        
        .endpoint-item {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 15px;
            margin: 10px 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: all 0.3s ease;
        }
        
        .endpoint-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            border-color: #667eea;
        }
        
        .endpoint-path {
            font-weight: bold;
            color: #667eea;
            font-size: 1.1rem;
        }
        
        .endpoint-description {
            color: #666;
            font-size: 0.9rem;
        }
        
        .status {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            margin-top: 20px;
        }
        
        .version {
            background: #17a2b8;
            color: white;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 0.9rem;
            margin-bottom: 20px;
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
            
            .endpoint-item {
                flex-direction: column;
                align-items: flex-start;
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">📦 SylisStock</div>
        <h1 class="title">Inventory Management API</h1>
        
        <div class="version">Version 1.0.0</div>
        
        <div class="api-info">
            <h2 style="margin-bottom: 20px; color: #333;">🔗 Available Endpoints</h2>
            <ul class="endpoint-list">
                <li class="endpoint-item">
                    <span class="endpoint-path">/inventory/</span>
                    <span class="endpoint-description">Stock management</span>
                </li>
                <li class="endpoint-item">
                    <span class="endpoint-path">/admin/</span>
                    <span class="endpoint-description">Admin panel</span>
                </li>
                <li class="endpoint-item">
                    <span class="endpoint-path">/auth/</span>
                    <span class="endpoint-description">Authentication</span>
                </li>
                <li class="endpoint-item">
                    <span class="endpoint-path">/inventory/docs/</span>
                    <span class="endpoint-description">API documentation</span>
                </li>
            </ul>
        </div>
        
        <div class="status">🟢 API Active</div>
        
        <div class="footer">
            <p>🚀 SylisStock API - Powered by Django REST Framework</p>
            <p>© 2024 SylisStock. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
        """
        return HttpResponse(template_content, content_type='text/html')
    else:
        # Return JSON response for API consumers
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
