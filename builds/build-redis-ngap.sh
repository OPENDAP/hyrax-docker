#!/bin/bash
#
source ./build-rh8
#
export DOCKER_NAME="ngap"
echo "DOCKER_NAME: ${DOCKER_NAME}"
#
export HYRAX_VERSION="hyrax-1.17.1"
export OLFS_VERSION="olfs-1.18.15"

export NGAP_DIT_IMAGE_TAG="opendap/hyrax:${DOCKER_NAME}-redis-session-manager"
export BUILD_VERSION_TAG=opendap/hyrax:${DOCKER_NAME}-${HYRAX_VERSION}
export TOMCAT_VERSION=$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")
#
show_version
#
get_tomcat_distro "${DOCKER_NAME}" "${TOMCAT_VERSION}"
#
s3_get_besd_distro \
    "${S3_BUILD_BUCKET}" \
    "${DOCKER_NAME}" \
    "el8" \
    "${LIBDAP_VERSION}" \
    "${BES_VERSION}" "${ADD_DEBUG_RPMS}"
#
get_ngap_olfs_distro \
    "${S3_BUILD_BUCKET}" \
    "${DOCKER_NAME}" \
    "${OLFS_VERSION}"
#
docker build \
       --build-arg TOMCAT_VERSION \
       --build-arg RELEASE_DATE \
       --build-arg HYRAX_VERSION \
       --build-arg LIBDAP_VERSION \
       --build-arg BES_VERSION \
       --build-arg OLFS_VERSION \
       --tag "${NGAP_DIT_IMAGE_TAG}" \
       "${DOCKER_NAME}"
#
docker image ls -a
