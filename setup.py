from setuptools import setup, find_packages
setup(
    name = "docker-registry-driver-gcs",
    version = "0.1",
    packages = find_packages(),
    install_requires = ['gcs-oauth2-boto-plugin==1.8'],
    namespace_packages = ['docker_registry', 'docker_registry.drivers']
)
