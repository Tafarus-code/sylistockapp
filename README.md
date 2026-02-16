sylistock - Django project scaffold

This workspace contains a minimal Django scaffold for the `sylistock` project.

Prerequisites
- Python 3.12 installed (recommended). Use `py -3.12` on Windows if available.

Quick start (cmd.exe)

1) Open cmd.exe and go to the project directory:

```cmd
cd /d C:\Users\tafar\IdeaProjects\sylistockapp
```

2) Ensure Python 3.12 is available (optional):

```cmd
ensure_python.bat
```

3) Create and activate a virtual environment with Python 3.12 (recommended):

```cmd
py -3.12 -m venv env
env\Scripts\activate
```

If `py` isn't available but `python` points to 3.12:

```cmd
python -m venv env
env\Scripts\activate
```

4) Upgrade pip and install dependencies:

```cmd
python -m pip install --upgrade pip
pip install -r requirements.txt
```

5) Run initial migrations and start the dev server:

```cmd
python manage.py migrate
python manage.py runserver
```

If you want me to create an app, wire it into `INSTALLED_APPS`, or run these commands here, tell me and I'll proceed.
