#!/bin/bash

GUNICORN_WORKERS=${GUNICORN_WORKERS:-1}
REGISTRY_PORT=${REGISTRY_PORT:-5000}
GUNICORN_GRACEFUL_TIMEOUT=${GUNICORN_GRACEFUL_TIMEOUT:-3600}
GUNICORN_SILENT_TIMEOUT=${GUNICORN_SILENT_TIMEOUT:-3600}

USAGE="docker run -e GCS_BUCKET=yet-another-docker-bucket \
[-e BOTO_PATH='/.config/gcloud/legacy_credentials/<YOUR_EMAIL>/.boto'] \
[-e GCP_OAUTH2_REFRESH_TOKEN=<refresh token>] \
-p 5000:5000 \
[--volumes-from gcloud-config] google/docker-registry"

if [[ -z GCS_BUCKET ]]; then
  echo "GCS_BUCKET not defined"
  echo
  echo "$USAGE"
  exit 1
fi

# If a refresh token is passed in directly, use that.
if [[ -n "$GCP_OAUTH2_REFRESH_TOKEN" ]]; then
  cat >/etc/boto.cfg <<EOF
[Credentials]
gs_oauth2_refresh_token = $GCP_OAUTH2_REFRESH_TOKEN
EOF
  BOTO_PATH=/etc/boto.cfg
  echo "Using credentails specified in GCP_OAUTH2_REFRESH_TOKEN env variable"
fi

# Look to see if something is mounted under the /.config dir
if [[ -z "${BOTO_PATH}" ]]; then
  BOTO_PATH=${BOTO_PATH:-$(find /.config | grep .boto | head -n 1)}
fi

if [[ -n "${BOTO_PATH}" ]]; then
  echo "Using credentials in ${BOTO_PATH}"
else
  wget -q --header='Metadata-Flavor: Google' \
    http://metadata.google.internal./computeMetadata/v1/instance/service-accounts/default/scopes \
    -O - | grep devstorage > /dev/null
  GCE_SA=$?

  if [[ $GCE_SA -eq 0 ]]; then
    echo "Using credentials from GCE Service Account"
  else
    echo "Boto credentials not found.  Either:"
    echo " - Set GCP_OAUTH2_REFRESH_TOKEN"
    echo " - Mount credentials under /.config in the container"
    echo " - Run in GCE with a service account configured for access"
    echo
    echo "$USAGE"
    exit 1
  fi
fi

export GCS_BUCKET BOTO_PATH

cd "$(dirname $0)"
exec gunicorn --access-logfile - --debug --max-requests 100 --graceful-timeout $GUNICORN_GRACEFUL_TIMEOUT -t $GUNICORN_SILENT_TIMEOUT -k gevent -b 0.0.0.0:$REGISTRY_PORT -w $GUNICORN_WORKERS wsgi:application
