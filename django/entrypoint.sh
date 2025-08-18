#!/usr/bin/env bash
set -e

# Wait for Postgres
until python - <<'PY'
import os, time
import psycopg2
host=os.getenv('POSTGRES_HOST','db')
port=int(os.getenv('POSTGRES_PORT','5432'))
user=os.getenv('POSTGRES_USER')
password=os.getenv('POSTGRES_PASSWORD')
db=os.getenv('POSTGRES_DB')
try:
    psycopg2.connect(host=host, port=port, user=user, password=password, dbname=db)
    print('Postgres is ready')
except Exception as e:
    print('Waiting for Postgres...', e)
    raise SystemExit(1)
PY

do
  echo "Retrying DB connection in 2s..." && sleep 2
done || true

python app/manage.py migrate --noinput

# Create superuser if not exists (optional convenience)
python - <<'PY'
import os
from django.core.management import execute_from_command_line
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')
try:
    from django.contrib.auth import get_user_model
    import django; django.setup()
    User=get_user_model()
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser('admin','admin@example.com','admin')
        print('Created default admin: admin/admin')
except Exception as e:
    print('Superuser creation skipped:', e)
PY

# Run dev server
python app/manage.py runserver 0.0.0.0:8000