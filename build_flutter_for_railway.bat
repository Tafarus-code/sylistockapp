@echo off
echo Building Flutter app for Railway deployment...

echo.
echo Step 1: Building Flutter web app...
cd mobile_app
call flutter build web
if %ERRORLEVEL% NEQ 0 (
    echo Flutter build failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Copying built app to Django static files...
cd ..
xcopy "mobile_app\build\web" "sylistock\sylistockapp\static\flutter" /E /Y /Q
if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy Flutter build files!
    pause
    exit /b 1
)

echo.
echo Step 3: Collecting Django static files...
cd sylistock
call python manage.py collectstatic --noinput
if %ERRORLEVEL% NEQ 0 (
    echo Django collectstatic failed!
    pause
    exit /b 1
)

echo.
echo ✅ Build complete! Your Flutter app is ready for Railway deployment.
echo.
echo The Flutter app will:
echo - Serve as the homepage at the root URL
echo - Automatically connect to the Railway backend API
echo - Save inventory data to the database
echo.
pause
