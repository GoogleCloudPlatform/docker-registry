#!/bin/bash

GUNICORN_WORKERS=${GUNICORN_WORKERS:-1}
REGISTRY_PORT=${REGISTRY_PORT:-5000}
GUNICORN_GRACEFUL_TIMEOUT=${GUNICORN_GRACEFUL_TIMEOUT:-3600}
GUNICORN_SILENT_TIMEOUT=${GUNICORN_SILENT_TIMEOUT:-3600}

USAGE="docker run -e GCS_BUCKET=yet-another-docker-bucket \
[-e BOTO_PATH='/.config/gcloud/legacy_credentials/<YOUR_EMAIL>/.boto'] -p 5000:5000 \
--volumes-from gcloud-config google/docker-registry"

GCS_BUCKET=${GCS_BUCKET:?"bucket not defined: ${USAGE}"}
BOTO_PATH=${BOTO_PATH:-$(find /.config | grep .boto | head -n 1)}
wget -qO- http://metadata.google.internal || BOTO_PATH=${BOTO_PATH:?"boto credentials not found: ${USAGE}"}
export GCS_BUCKET BOTO_PATH

cd "$(dirname $0)"
exec gunicorn --access-logfile - --debug --max-requests 100 --graceful-timeout $GUNICORN_GRACEFUL_TIMEOUT -t $GUNICORN_SILENT_TIMEOUT -k gevent -b 0.0.0.0:$REGISTRY_PORT -w $GUNICORN_WORKERS wsgi:application
