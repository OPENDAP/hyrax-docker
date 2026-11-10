
# Howto: Build the hyrax builder images

## Build EL9 Docker Image

The script `hyrax-docker/utils/mk_rocky9_hyrax_builder` will build the Docker image using the Dockerfile  in `hyrax-docker/utils/build-rhel9`

The directory `hyrax-docker/utils/build-rhel9` has the Dockerfile used 
by `mk_rocky9_hyrax_builder` to create the docker image for build libdap4 on rh9

```
cd hyrax-docker/utils
sudo ./mk_rocky9_hyrax_builder
```
* If you set and export the env variable `image_tag`:
```export image_tag="opendap/rocky9_hyrax_builder:MyTestImage```
The script(s) will use that tag.
* If you supply a DockerHub user id and password as parameters 1 and 2 (respectively) in the command line inmvocation the script will attempt to push the tagged image to DockerHub. 
* If you supply _any_ 3rd parameter this will cause the build to run in no-cache mode (slow but thorough)

This
```bash
export image_tag="opendap/rocky9_hyrax_builder:MyTestImage
./mk_rocky9_hyrax_builder foofoo booboo x
```
Will build the el9 builder image tag it with `opendap/rocky9_hyrax_builder:MyTestImage`, and use the uid foofoo and password booboo to login and push the image to DockerHub. the "x" as a third parameter will cause the build to run in no-cache mode.

If you want to run in no-cache mode but don't want to do the Docker Hub part then do this:
```bash
./mk_rocky9_hyrax_builder "" "" x
```

## Build Libdap4 RPMs using the Docker image

The script `./test-rh9` will attempt to build libdap4 using the 
Docker image built by `mk_rocky9_hyrax_builder`.

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


## Build the EL8 image
Pretty mucb the same as the EL9 build, but uses: 
* hyrax-docker/utils/mk_rocky8_hyrax_builder
* hyrax-docker/utils/rocky8_hyrax_builder/Dockerfile (and others)
* hyrax-docker/utils/test-rh8

---

# How to update the builder images in production.
At the time of this writing, there are no CICD tasks to produce and test these images. What follows is the hand built way.

## Make a hyrax-docker branch
Change to your new branch and use it for what follows.
* If you need to modify the Docker file(s) in order to change something, now would be the time
* If you only need to update the builder image(s) to get the lastest patches just move on. 

## Build The Image
Use the scripts described above:
* `docker/utils/mk_rocky9_hyrax_builder`
* `docker/utils/mk_rocky8_hyrax_builder`
* `docker/utils/mk_ubuntu_hyrax_builder`
 
## Tag The Image
It's easiest to tag the image when you run the build script:

```bash
export image_tag="opendap/rocky9_hyrax_builder:MyTestImage
./mk_rocky9_hyrax_builder 
```

## Push The Image
By supplying valid DockerHub credentials you will cause the scripts to push the image after it's built:
```bash
export image_tag="opendap/rocky9_hyrax_builder:MyTestImage
./mk_rocky9_hyrax_builder foofoo booboo
```
Where `foofoo` is the DockerHub user id and `booboo` is _foofoo_'s DockerHub password.
## Make a libdap4 & BES branches

### libdap4

* Make a branch and change to it
* In the _libdap4/.travis.yml_ file search for "hyrax_builder:latest" and update what you find as needed for your test builder image tag.
* Push your branch changes.
* Make a PR for your branch
* Watch for smoke.

### BES
* Make a branch and change to it

* In the bes/.travis.yml file update the BUILDER_BASE_IMAGE for each build to match your newly published test images:

```bash
    export BUILDER_BASE_IMAGE="opendap/rocky8_hyrax_builder:MyTestImage"
```

```bash
    export BUILDER_BASE_IMAGE="opendap/rocky9_hyrax_builder:MyTestImage"
```
* Push your changes.
* Make a PR for your branch.
* And then watch for smoke.

# Finishing up

If/When it all works (aka no smoke) and you are satisfied with the changes to your _hyrax-docker_ branch, then proceed to the following.

* Retag your test image be "latest".
: `opendap/rocky9_hyrax_builder:MyTestImage` --> `opendap/rocky9_hyrax_builder:latest`

* Push that `latest` tag to DockerHub

* Merge your _hyrax-docker_ branch to _master_. This will capture your changes, but only the regular CICD activities will happen. The "builder" images will not be built by TravisCI.

* You can then close the libdap4 and BES PRs without merging, and delete the associated branches.

* Watch for smoke from the TravisCI builds on master for the libdap4 and BES after you make these changes.





