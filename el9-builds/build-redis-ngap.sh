#!/bin/bash
#
source ./build-el9
#
export DOCKER_NAME="ngap"
loggy "DOCKER_NAME: ${DOCKER_NAME}"
#
export TOMCAT_VERSION=
TOMCAT_VERSION="$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")"
#
export APR_VERSION="1.7.6-1"
loggy "APR_VERSION: $APR_VERSION"
#
export OPENSSL_VERSION="3.5.0-4"
loggy "OPENSSL_VERSION: $OPENSSL_VERSION"
#
show_version
#
get_tomcat_distro "$DOCKER_NAME" "$TOMCAT_VERSION"
#

s3_get_besd_distro \
    "$S3_BUILD_BUCKET" \
    "$DOCKER_DIR" \
    "$TARGET_OS" \
    "$LIBDAP_VERSION" \
    "$BES_VERSION" "$ADD_DEBUG_RPMS"
#
s3_get_apache_apr_distro \
    "$S3_BUILD_BUCKET" \
    "$DOCKER_DIR" \
    "$APR_VERSION" \
    "$ADD_DEBUG_RPMS"

s3_get_olfs_ngap_distro \
  "$S3_BUILD_BUCKET" \
  "$DOCKER_DIR" \
  "$OLFS_VERSION" 2>&1

s3_get_openssl_distro \
    "$S3_BUILD_BUCKET" \
    "$DOCKER_DIR" \
    "$OPENSSL_VERSION" \
    "$TARGET_OS" \
    "$ADD_DEBUG_RPMS"
#
set -e
docker build \
       --build-arg TOMCAT_VERSION \
       --build-arg RELEASE_DATE \
       --build-arg HYRAX_VERSION \
       --build-arg LIBDAP_VERSION \
       --build-arg BES_VERSION \
       --build-arg OLFS_VERSION \
       --build-arg OPENSSL_VERSION \
       --tag "${SNAPSHOT_IMAGE_TAG}" \
       --tag "${BUILD_VERSION_TAG}" \
       "${DOCKER_NAME}"
#
set +e

loggy "$(docker image ls -a)"
