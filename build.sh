#!/usr/bin/env bash
# Exit on error
set -o errexit

# Upgrade pip and install dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt

# Collect static assets and run database migrations
python sylistock/manage.py collectstatic --no-input
python sylistock/manage.py migrate

# Exit successfully
exit 0
