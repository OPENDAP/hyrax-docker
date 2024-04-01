#!/bin/bash
BUILD_DIR=${BUILD_DIR:-"./builds"}

echo "# build_from_woo ####################################################" >&2

start_dir=$(pwd)
latest_release_recipe=$(ls -t -F1 $start_dir/releases/hyrax* | head -1)
echo "latest_release_recipe: ${latest_release_recipe}" >&2

BUILD_RECIPE=${1:-$latest_release_recipe}
echo "# BUILD_RECIPE: ${BUILD_RECIPE}" >&2

cd "${BUILD_DIR}" || exit
source ./build-rh8 "${BUILD_RECIPE}"
export TOMCAT_VERSION=$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")
show_version

HYRAX_MAJOR_VERSION=$(echo $HYRAX_VERSION | awk '{split($0,v,"."); print v[1]"."v[2];}')
loggy "HYRAX_MAJOR_VERSION: $HYRAX_MAJOR_VERSION"

# Get the latest TOMCAT distribution
get_tomcat_distro `pwd` "${TOMCAT_VERSION}"

# Get the BES and libdap RPMs
woo_get_besd_distro \
    `pwd` \
    "el8" \
    "${LIBDAP_VERSION}" \
    "${BES_VERSION}" \
    "${HYRAX_VERSION}" \
     true

# Get the OLFS web archive
woo_get_olfs_distro \
    `pwd` \
    "${OLFS_VERSION}"

ls -l *.rpm *.gz *.tgz

targets="hyrax" # hyrax besd build_dmrpp ngap olfs
for docker_name in $targets
do
    loggy "$HR2"
    loggy "Building Docker image for $docker_name"
    loggy ""

    cp -v *.rpm ${docker_name} >&2
    cp -v "olfs-${OLFS_VERSION}"* ${docker_name} >&2
    cp -v "robots-olfs-${OLFS_VERSION}"* ${docker_name} >&2
    cp -v "apache-tomcat-${TOMCAT_VERSION}"* ${docker_name} >&2

    loggy "BUILDING docker image for $docker_name"
    docker build \
        --build-arg TOMCAT_VERSION \
        --build-arg RELEASE_DATE \
        --build-arg HYRAX_VERSION \
        --build-arg LIBDAP_VERSION \
        --build-arg BES_VERSION \
        --build-arg OLFS_VERSION \
        --tag "${SNAPSHOT_IMAGE_TAG}" \
        --tag "${BUILD_VERSION_TAG}" \
        --tag "${HYRAX_VERSION}" \
        "${docker_name}"
    docker image ls -a
    cd ..
    loggy  "Running Test Script"
    ./regression_test_script -i ${SNAPSHOT_IMAGE_TAG}

    loggy "Cleaning up binaries in $docker_name"
    rm  -v "${BUILD_DIR}/${docker_name}"/*.rpm
    rm -rv "${BUILD_DIR}/${docker_name}/olfs-${OLFS_VERSION}"*
    rm  -v "${BUILD_DIR}/${docker_name}/robots-olfs-${OLFS_VERSION}"*
    rm -rv "${BUILD_DIR}/${docker_name}/apache-tomcat-${TOMCAT_VERSION}"*
done

loggy "Cleaning up binaries in ${BUILD_DIR}"
rm  -v "${BUILD_DIR}"/*.rpm
rm -rv "${BUILD_DIR}/olfs-${OLFS_VERSION}"*
rm  -v "${BUILD_DIR}/robots-olfs-${OLFS_VERSION}"*
rm -rv "${BUILD_DIR}/apache-"*

