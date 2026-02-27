from django.http import HttpResponse
import os


def flutter_app(request):
    """
    Serve Flutter web application
    """
    # Path to the Flutter web build
    flutter_index_path = os.path.join(
        os.path.dirname(__file__),
        'static',
        'flutter',
        'index.html'
    )

    try:
        with open(flutter_index_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if we are in production (Railway) or development
        if 'RAILWAY_ENVIRONMENT' in os.environ or 'RAILWAY_SERVICE_NAME' in os.environ:
            # Production: Use absolute path for Railway
            base_href = "/static/flutter/"
        else:
            # Development: Use relative path
            base_href = "/static/flutter/"

        # Update base href for proper asset loading
        content = content.replace(
            '<base href="/">',
            f'<base href="{base_href}">'
        )

        # Add CSP header for security
        response = HttpResponse(content, content_type='text/html')
        csp_policy = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data:; "
            "font-src 'self' data:;"
        )
        response['Content-Security-Policy'] = csp_policy

        return response

    except FileNotFoundError:
        return HttpResponse(
            """
            <html>
            <head><title>Flutter App Not Found</title></head>
            <body>
                <h1>Flutter App Not Found</h1>
                <p>Please build the Flutter app first:</p>
                <pre>cd mobile_app && flutter build web</pre>
                <p>Then run:</p>
                <pre>python manage.py collectstatic --noinput</pre>
            </body>
            </html>
            """,
            content_type='text/html'
        )
