# docker-registry-driver-gcs

**Update, February 2015**: We've launched [Google Container Registry](https://cloud.google.com/tools/container-registry/) and recommend using it instead of docker-registry. Container Registry is a private Docker registry running on Google Cloud Storage. It uses the same authentication, storage, and billing as docker-registry, without the need to run a host instance for your registry. Images on Google Container Registry can be accessed easily from Google Compute Engine, Managed VMs, Google Container Engine, non-Google cloud providers, or your own machines.

---

Sources for [google/docker-registry](https://index.docker.io/u/google/docker-registry/), [Docker Registry](https://github.com/dotcloud/docker-registry) image to push/pull your [Docker](https://www.docker.io/) images to/from [Google Cloud Storage](https://cloud.google.com/products/cloud-storage/).

- Define 'gcs' as a storage plugin
- Has OAuth2 support built in
- Works locally and on [Google Compute Engine](https://cloud.google.com/products/compute-engine/)

## Usage

After [google/docker-registry](https://index.docker.io/u/google/docker-registry) is built or pulled from the [public registry]( https://index.docker.io/u/google/docker-registry) you can push/pull docker images to/from your [Google Cloud Storage](https://cloud.google.com/products/cloud-storage/) bucket.

### Specifying the bucket

You need to specify the GCS bucket to store your images in.  To do that, set the `GCS_BUCKET` environment variable when running the Docker container.

    docker run -d -e GCS_BUCKET=your-bucket -p 5000:5000 google/docker-registry

You can optionally set the `STORAGE_PATH` environment variable to specify the path to the registry location inside the bucket.  Make sure to have a leading slash and not have a trailing one in the path specification.

    docker run -d -e GCS_BUCKET=your-bucket -e STORAGE_PATH=/containers -p 5000:5000 google/docker-registry

### Credentials

There are three ways to specify the credentials:

1. Specify the Google Cloud Platform OAuth refresh token directly in an environment variable.  It is best to put this in an `--env-file` so it can't be seen with `ps` when not running detached.  Example:

        $ gcloud auth print-refresh-token
        ...your-refresh-token...
        $ cat registry-params.env
        GCP_OAUTH2_REFRESH_TOKEN=your-refresh-token
        GCS_BUCKET=your-bucket
        $ docker run -d --env-file=registry-params.env -p 5000:5000 google/docker-registry

1.  A `.boto` file in the `/.config` directory in the `docker-registry` container. The easiest way to do this is to use the `google/cloud-sdk` Docker image to create these credentials, and import its `/.config` volume using `--volumes-from`.

        $ docker run -ti --name gcloud-config google/cloud-sdk gcloud auth login
        Go to the following link in your browser:

            https://accounts.google.com/o/oauth2/auth [snip]

        Enter verification code: [snip]

        You are now logged in as [you@gmail.com].
        Your current project is [None].  You can change this setting by running:
          $ gcloud config set project <project>

        $ docker run -ti --volumes-from gcloud-config google/cloud-sdk \
            gcloud config set project <project>

        $ docker run -d -e GCS_BUCKET=your-bucket -p 5000:5000 \
            --volumes-from gcloud-config google/docker-registry

1. Run on [Google Compute Engine](https://cloud.google.com/products/compute-engine/) with a properly configured service account:

        $ gcutil addinstance --zone=us-central1-a --machine_type=f1-micro \
            --image=projects/google-containers/global/images/container-vm-v20140522 \
            --service_account_scopes=storage-rw \
            my-docker-vm

        [snip]

        $ gcutil ssh my-docker-vm
        $ sudo docker run -d -e GCS_BUCKET=your-bucket -p 5000:5000 google/docker-registry

### Using the registry

    docker tag myawesomeimage localhost:5000/myawesomeimage
    docker push localhost:5000/myawesomeimage

## Building google/docker-registry image

    docker build -t google/docker-registry .

## Notes

Current image size: 428.8 MB

