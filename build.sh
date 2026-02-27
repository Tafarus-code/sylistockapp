#!/bin/bash
# Exit on error
set -o errexit

# Upgrade pip and install dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt

# Build Flutter web app
echo "Building Flutter web app..."
cd mobile_app
flutter build web --base-href "/app/"
cd ..

# Collect static assets and run database migrations
echo "Collecting Django static files..."
python sylistock/manage.py collectstatic --no-input --clear
python sylistock/manage.py migrate

# Exit successfully
exit 0
