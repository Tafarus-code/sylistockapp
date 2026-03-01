#!/bin/bash
# Exit on error
set -o errexit

# Upgrade pip and install dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt

# Note: Flutter app should be pre-built locally before deployment
# Run these commands locally before pushing to Railway:
# cd mobile_app && flutter build web --base-href "/app/" && cd ..

# Collect static assets and run database migrations
echo "Collecting Django static files..."
python sylistock/manage.py collectstatic --no-input --clear
python sylistock/manage.py migrate --fake-initial

# Exit successfully
exit 0
