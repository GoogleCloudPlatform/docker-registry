#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update || true
apt-get install -y --no-install-recommends \
    git-core gcc python-dev \
    gunicorn python-boto liblzma-dev \
    python-yaml python-lzma python-crypto python-requests \
    python-simplejson python-redis python-openssl wget python-pip
rm /var/lib/apt/lists/*_*
apt-get clean

(cd /docker-registry && pip install -r requirements.txt)

apt-get purge -y --force-yes gcc python-dev git-core
apt-get autoremove -y --force-yes
