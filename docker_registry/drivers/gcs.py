import gevent.monkey
gevent.monkey.patch_all()

import logging

import boto.gs.connection
import boto.gs.key

from docker_registry.core import lru
from docker_registry.core import boto as coreboto

logger = logging.getLogger(__name__)

class Storage(coreboto.Base):

    def __init__(self, path, config):
        super(Storage, self).__init__(path, config)

    def _build_connection_params(self):
        kwargs = super(Storage, self)._build_connection_params()
        if self._config.gs_secure is not None:
            kwargs['is_secure'] = (self._config.gs_secure is True)
        return kwargs

    def makeConnection(self):
        if self._config.oauth2 is True:
            # add the GoogleCompute / service_account flag to the boto.config
            # so that gcs_oauth2_boto_plugin will enable loading credentials from GCE metadata
            boto.config.save_system_option("GoogleCompute","service_account","true")
            from gcs_oauth2_boto_plugin import oauth2_plugin
            uri = boto.storage_uri(self._config.boto_bucket, 'gs')
            return uri.connect()

        kwargs = self._build_connection_params()
        return boto.gs.connection.GSConnection(
            self._config.gs_access_key,
            self._config.gs_secret_key,
            **kwargs)

    def makeKey(self, path):
        return boto.gs.key.Key(self._boto_bucket, path)

    @lru.set
    def put_content(self, path, content):
        path = self._init_path(path)
        key = self.makeKey(path)
        key.set_contents_from_string(content)
        return path

    def stream_write(self, path, fp):
        # Minimum size of upload part size on GS is 5MB
        buffer_size = 5 * 1024 * 1024
        if self.buffer_size > buffer_size:
            buffer_size = self.buffer_size
        path = self._init_path(path)
        key = self.makeKey(path)
        key.set_contents_from_string(fp.read())
