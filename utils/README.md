
# RH-9 Build

## Build RH9 Docker Image

The script `hyrax-docker/utils/dckrbld` will build the Docker image using the Dockerfile  in `hyrax-docker/utils/build-rhel9`

The directory `hyrax-docker/utils/build-rhel9` has the Dockerfile used 
by `dckrbld` to create the docker image for build libdap4 on rh9

```
cd hyrax-docker/utils
sudo ./dckrbld
```
## Build Libdap4 RPMs using the Docker image

The script `./test-rh9` will attempt to build libdap4 using the 
Docker image built by `dckrbld`.

The script `hyrax-docker/utils/test-rh9` will:
- Remove the current libdap4 directory
- Clone a fresh libdap4 and checkout the branch RHEL9
- Start the docker image built by dckrbld mounting the freshly cloned libdap4 to /root/libdap4
- Run the libdap4 build script `hyrax-docker/utils/libdap4/travis/build-rpm-9.sh` which will be mounted to: `/root/libdap4/travis/build-rpm-9.sh`

```
sudo ./test-rh9
``` 
**NOTE**: The list of things that are `yum` installed on the Rocky9 machine in `us-west-2` (named `rocky9`) that Dan used to build the stuff for our RH9 assessment is located in 
`hyrax-docker/utils/build-rhel9/aws-ecs-rocky9-yum-inventory.txt`