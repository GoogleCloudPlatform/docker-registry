#!/bin/bash

GUNICORN_WORKERS=${GUNICORN_WORKERS:-1}
REGISTRY_PORT=${REGISTRY_PORT:-5000}
GUNICORN_GRACEFUL_TIMEOUT=${GUNICORN_GRACEFUL_TIMEOUT:-3600}
GUNICORN_SILENT_TIMEOUT=${GUNICORN_SILENT_TIMEOUT:-3600}

export BOTO_PATH=/.config/gcloud/legacy_credentials/${EMAIL}/.boto

cd "$(dirname $0)"
exec gunicorn --access-logfile - --debug --max-requests 100 --graceful-timeout $GUNICORN_GRACEFUL_TIMEOUT -t $GUNICORN_SILENT_TIMEOUT -k gevent -b 0.0.0.0:$REGISTRY_PORT -w $GUNICORN_WORKERS wsgi:application
