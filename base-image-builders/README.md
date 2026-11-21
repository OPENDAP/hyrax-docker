
# RH-9 Build

## Build RH9 Docker Image

The script `hyrax-docker/base-image-builders/mk_rocky9_hyrax_builder` will build the Docker image using the Dockerfile  in `hyrax-docker/base-image-builders/rocky9-hyrax-builder`

The directory `hyrax-docker/base-image-builders/rocky9-hyrax-builder` has the Dockerfile used 
by `mk_rocky9_hyrax_builder` to create the docker image for build libdap4 on rh9

```
cd hyrax-docker/base-image-builders
sudo ./mk_rocky9_hyrax_builder
```
## Build Libdap4 RPMs using the Docker image

The script `./test-rh9` will attempt to build libdap4 using the 
Docker image built by `mk_rocky9_hyrax_builder`.

The script `hyrax-docker/base-image-builders/test-rh9` will:
- Remove the current libdap4 directory
- Clone a fresh libdap4 and checkout the branch RHEL9
- Start the docker image built by `mk_rocky9_hyrax_builder` mounting the freshly cloned libdap4 to /root/libdap4
- Run the libdap4 build script `hyrax-docker/base-image-builders/libdap4/travis/build-rpm-9.sh` which will be mounted to: `/root/libdap4/travis/build-rpm-9.sh`

```
sudo ./test-rh9
``` 
**NOTE**: The list of things that are `yum` installed on the Rocky9 machine in `us-west-2` (named `rocky9`) that Dan used to build the stuff for our RH9 assessment is located in 
`hyrax-docker/base-image-builders/build-rhel9/aws-ecs-rocky9-yum-inventory.txt`