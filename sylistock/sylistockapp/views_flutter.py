from django.http import HttpResponse
import os


def flutter_app(request):
    """
    Serve the Flutter web application
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

        # Update base href if needed for proper asset loading
        content = content.replace(
            '<base href="/">',
            '<base href="/static/flutter/">'
        )

        return HttpResponse(content, content_type='text/html')

    except FileNotFoundError:
        return HttpResponse(
            """
            <html>
            <head><title>Flutter App Not Found</title></head>
            <body>
                <h1>Flutter App Not Found</h1>
                <p>Please build the Flutter app first:</p>
                <pre>cd mobile_app && flutter build web</pre>
            </body>
            </html>
            """,
            content_type='text/html'
        )
