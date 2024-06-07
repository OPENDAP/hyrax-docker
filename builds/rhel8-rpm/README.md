# Support for building RPM packages for RHEL 8

This directory contains a Dockerfile that can be used to build a Rocky8
VM that can then be used to build our C++ software and produce RPM packages.

Run ```docker build -t rocky8_hyrax_builder .``` to build the Docker image.

To build tagged images for upload to DockerHub, run: 
```
docker build -t opendap/rocky8_hyrax_builder:latest -t opendap/rocky8_hyrax_builder:1.0 \
    -t opendap/rocky8_hyrax_builder:1 .
```
in this directory, so that the Dockerfile can be found.

Then login to DockerHub in an account that can push to the 'opendap' organization
and use ```docker push opendap/rocky8_hyrax_builder:lastest```, ...,  to push the images
to DockerHub.

NB: If the image name changes from rocky8_hyrax_builder to something else, a new
DockerHub repo will need to be created under the 'opendap' organization.
