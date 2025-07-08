#!/bin/bash
#
source ./build-rh8
#
export DOCKER_NAME="ngap"
echo "DOCKER_NAME: ${DOCKER_NAME}"
#
export NGAP_DIT_IMAGE_TAG="opendap/hyrax:${DOCKER_NAME}-redis-session-manager"
export SNAPSHOT_IMAGE_TAG="opendap/hyrax:${DOCKER_NAME}-redis-session-manager"
export BUILD_VERSION_TAG=opendap/hyrax:${DOCKER_NAME}-${HYRAX_VERSION}
export TOMCAT_VERSION=$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")
#export TOMCAT_VERSION="11.0.8"
#
export APR_VERSION="1.7.6-1"
echo "APR_VERSION: ${APR_VERSION}"
#
export OPENSSL_VERSION="3.5.0-4"
echo "OPENSSL_VERSION: ${OPENSSL_VERSION}"
#
show_version
#
get_tomcat_distro "${DOCKER_NAME}" "${TOMCAT_VERSION}"
#

s3_get_besd_distro \
    "${S3_BUILD_BUCKET}" \
    "${DOCKER_NAME}" \
    "el9" \
    "${LIBDAP_VERSION}" \
    "${BES_VERSION}" "${ADD_DEBUG_RPMS}"
#
s3_get_apache_apr_distro \
    "${S3_BUILD_BUCKET}" \
    "${DOCKER_NAME}" \
    "${APR_VERSION}" "${ADD_DEBUG_RPMS}"
#
get_ngap_olfs_distro \
    "${S3_BUILD_BUCKET}" \
    "${DOCKER_NAME}" \
    "redisson-3.48.0"
#
s3_get_openssl_distro \
    "${S3_BUILD_BUCKET}" \
    "${DOCKER_NAME}" \
    "${OPENSSL_VERSION}" \
    "el9" \
    "${ADD_DEBUG_RPMS}"
#
docker build \
       --build-arg TOMCAT_VERSION \
       --build-arg RELEASE_DATE \
       --build-arg HYRAX_VERSION \
       --build-arg LIBDAP_VERSION \
       --build-arg BES_VERSION \
       --build-arg OLFS_VERSION \
       --build-arg OPENSSL_VERSION \
       --tag "${NGAP_DIT_IMAGE_TAG}" \
       "${DOCKER_NAME}"
#
docker image ls -a
