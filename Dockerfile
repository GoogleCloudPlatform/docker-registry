FROM google/debian:wheezy

RUN apt-get update \
    && apt-get install --no-install-recommends -yq python-pip build-essential python-dev liblzma-dev libffi-dev curl openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN pip install docker-registry==0.9

ADD requirements.txt /docker-registry-gcs-plugin/requirements.txt
RUN pip install -r  /docker-registry-gcs-plugin/requirements.txt
ADD setup.py /docker-registry-gcs-plugin/setup.py
ADD docker_registry /docker-registry-gcs-plugin/docker_registry
RUN pip install /docker-registry-gcs-plugin

# Vendor patch to address #22 - can be removed once docker-registry==1.0 lands.
RUN cd /usr/local/lib/python2.7/dist-packages \
    && curl -s https://github.com/docker/docker-registry/commit/3962264535907231670d9ff74d1c7f3ec7f8bf87.diff | patch -p1

ENV DOCKER_REGISTRY_CONFIG /docker-registry/config/config.yml
ADD config.yml /docker-registry/config/
ADD run.sh /docker-registry/

# Credentials. Use --volumes-from gcloud-config (google/cloud-sdk).
VOLUME ["/.config"]

# ssl certs
VOLUME ["/ssl"]
VOLUME ["/certs.d"]

# These should be set if credentials are obtained with google/cloud-sdk.
ENV OAUTH2_CLIENT_ID 32555940559.apps.googleusercontent.com
ENV OAUTH2_CLIENT_SECRET ZmssLNjJy2998hD4CTg2ejr2
ENV USER_AGENT "Cloud SDK Command Line Tool"

EXPOSE 5000

ENV SETTINGS_FLAVOR prod
WORKDIR /docker-registry
CMD ["docker-registry"]
ENTRYPOINT ["./run.sh"]
