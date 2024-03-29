#!/bin/bash

HR="# mkRelease ###############################################################"

export DOCKER_RELEASE="hyrax-${HYRAX_FULL_VERSION}";
# Create files
mkdir -p "${DOCKER_RELEASE}"
cp snapshot.time "${DOCKER_RELEASE}/release_components"

myStuff=$(cat "${DOCKER_RELEASE}/release_components")

#export S3_BUILD_BUCKET=${S3_BUILD_BUCKET:-"opendap.travis.build"}
# export DOCKER_NAME=${DOCKER_NAME:-"hyrax"}

#export TOMCAT_MAJOR_VERSION=${TOMCAT_MAJOR_VERSION:-"9"}
#export SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
#export NO_CACHE=${NO_CACHE:-""}
export RELEASE_DATE=""
RELEASE_DATE=$(echo "${myStuff}" | grep hyrax | awk '{print $2;}')
echo "#          RELEASE_DATE: ${RELEASE_DATE}" >&2
export HYRAX_VERSION=""
HYRAX_VERSION=$(echo "${myStuff}" | grep hyrax | awk '{print $1;}')
echo "#         HYRAX_VERSION: ${HYRAX_VERSION}" >&2
export HYRAX_VERSION_NUMBER=""
HYRAX_VERSION_NUMBER=$(echo "${HYRAX_VERSION}" | sed "s/hyrax-//g" )
echo "#  HYRAX_VERSION_NUMBER: ${HYRAX_VERSION_NUMBER}" >&2
export OLFS_VERSION=""
OLFS_VERSION=$(echo "${myStuff}" | grep olfs | sed "s/olfs-//g" | awk '{print $1;}')
echo "#          OLFS_VERSION: ${OLFS_VERSION}" >&2
export BES_VERSION=""
BES_VERSION=$(echo "${myStuff}" | grep bes | sed "s/bes-//g" | awk '{print $1;}')
echo "#           BES_VERSION: ${BES_VERSION}" >&2
export LIBDAP_VERSION=""
LIBDAP_VERSION=$(echo "${myStuff}" | grep libdap4 | sed "s/libdap4-//g"| awk '{print $1;}')
echo "#        LIBDAP_VERSION: ${LIBDAP_VERSION}" >&2
echo "#" >&2
#export SNAPSHOT_IMAGE_TAG=${SNAPSHOT_IMAGE_TAG:-"opendap/${DOCKER_NAME}:snapshot"}
#echo "#    SNAPSHOT_IMAGE_TAG: ${SNAPSHOT_IMAGE_TAG}" >&2
#export BUILD_VERSION_TAG=${BUILD_VERSION_TAG:-"opendap/${DOCKER_NAME}:${HYRAX_VERSION_NUMBER}"}
#echo "#     BUILD_VERSION_TAG: ${BUILD_VERSION_TAG}" >&2
echo "#" >&2
build_dir=$(pwd)"/builds"
echo "#             build_dir: ${build_dir}" >&2

cd "${build_dir}" || exit
source ./build-rh8

export TOMCAT_VERSION=$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")



function get_rpms(){
    echo ""

}



function get_release_from_woo(){
    local download_server="https://www.opendap.org"
    local libdap_version="3.20.10-0"
    local bes_version="3.20.12-0"
    local olfs_version="1.18.12-0"

    # RHEL-8
    local dir_name="pub/binary/hyrax-1.16/rhel-8"
    local larch="el8"

    local libdap_rpm="libdap-${libdap_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${libdap_rpm}" "."
    local libdap_devel_rpm="libdap-devel-${libdap_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${libdap_devel_rpm}" "."
    local libdap_debug_rpm="libdap-debuginfo-${libdap_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${libdap_debug_rpm}" "."

    local bes_rpm="bes-${bes_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${bes_rpm}" "."
    local bes_devel_rpm="bes-devel-${bes_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${bes_devel_rpm}" "."
    local bes_debug_rpm="bes-debuginfo-${bes_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${bes_debug_rpm}" "."

    # RHEL-7 (aka CentOS-7)
    dir_name="pub/binary/hyrax-1.16/centos-7.x"
    larch="el7"

    libdap_rpm="libdap-${libdap_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${libdap_rpm}" "."
    libdap_devel_rpm="libdap-devel-${libdap_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${libdap_devel_rpm}" "."
    libdap_debug_rpm="libdap-debuginfo-${libdap_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${libdap_debug_rpm}" "."

    bes_rpm="bes-${bes_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${bes_rpm}" "."
    bes_devel_rpm="bes-devel-${bes_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${bes_devel_rpm}" "."
    bes_debug_rpm="bes-debuginfo-${bes_version}.static.${larch}.x86_64.rpm"
    curl_pull  "${download_server}/${dir_name}" "${bes_debug_rpm}" "."

    dir_name="pub/olfs"
    olfs_dist="olfs-${olfs_version}-webapp.tgz"
    curl_pull  "${download_server}/${dir_name}" "${olfs_dist}" "."
    robots_olfs_dist="robots-olfs-${olfs_version}-webapp.tgz"
    curl_pull  "${download_server}/${dir_name}" "${olfs_dist}" "."

}
function hyrax_1_16_7(){
    bucket_url="https://s3.amazonaws.com/opendap.travis.build/"
    bes_version="3.20.12-0"
    libdap_version="3.20.10-0"
    olfs_version="1.18.12-0"
    larch="el8"

    get_release_from_s3
}



for docker_name in hyrax
do

    export SNAPSHOT_IMAGE_TAG="opendap/${docker_name}:snapshot"
    echo "#    SNAPSHOT_IMAGE_TAG: ${SNAPSHOT_IMAGE_TAG}" >&2
    export BUILD_VERSION_TAG="opendap/${docker_name}:${HYRAX_VERSION_NUMBER}"
    echo "#     BUILD_VERSION_TAG: ${BUILD_VERSION_TAG}" >&2


#    get_tomcat_distro "${docker_name}" "${TOMCAT_VERSION}"

    woo_get_besd_distro \
        `pwd` \
        "el8" \
        "${LIBDAP_VERSION}" \
        "${BES_VERSION}" true 2>&1

    woo_get_olfs_distro \
        "${S3_BUILD_BUCKET}" \
        "${docker_name}" \
        "${OLFS_VERSION}" 2>&1

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
    echo "Running Test Script"
    ./regression_test_script -i ${SNAPSHOT_IMAGE_TAG}
    #docker push ${SNAPSHOT_IMAGE_TAG}
    #docker push ${BUILD_VERSION_TAG}

    rm -v "${docker_name}/*.rpm"
    rm -rv "${docker_name}/olfs-${OLFS_VERSION}*"
    rm -v "${docker_name}/robots-olfs-${OLFS_VERSION}*"
    rm -rv "${docker_name}/apache-tomcat-${TOMCAT_VERSION}*"
done
}