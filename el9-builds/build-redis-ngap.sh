#!/bin/bash
#
export DOCKER_NAME="${DOCKER_NAME:-"ngap"}"

#
source ./build-el9
prolog="$0 -"

export DOCKER_NAME="${DOCKER_NAME:-"ngap"}"
loggy "$prolog DOCKER_NAME: $DOCKER_NAME"

###############################################################################################
# We overwrite the SNAPSHOT_IMAGE_TAG and BUILD_VERSION_TAG variables because the ngap product
# gets tagged differently than the products from our other repos.
# Specifically, we use the opendap/hyrax repo since the ngap product is just a specialization
# of hyrax, at least for now. So we use a fixed opendap/hyrax project, and we add the
# $DOCKER_NAME ("ngap" in this case) to the image tag:
# Examples:
#     opendap/hyrax:ngap-snapshot-el9
#     opendap/hyrax:ngap-1.17.1-846-el9
#     opendap/hyrax:ngap-snapshot-el9-test-deploy
#     opendap/hyrax:ngap--1.17.1-846-el9-test-deploy
#
export SNAPSHOT_IMAGE_TAG="${SNAPSHOT_IMAGE_TAG:-"opendap/hyrax:$DOCKER_NAME-snapshot-$TARGET_OS$TEST_DEPLOYMENT"}"
loggy "$prolog SNAPSHOT_IMAGE_TAG: $SNAPSHOT_IMAGE_TAG" >&2
#
export BUILD_VERSION_TAG="${BUILD_VERSION_TAG:-"opendap/hyrax:$DOCKER_NAME-$HYRAX_VERSION-$TARGET_OS$TEST_DEPLOYMENT"}"
loggy "$prolog BUILD_VERSION_TAG: $BUILD_VERSION_TAG" >&2
###############################################################################################


loggy "$prolog TOMCAT_MAJOR_VERSION: $TOMCAT_MAJOR_VERSION" >&2
export TOMCAT_VERSION=
TOMCAT_VERSION="$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")"
loggy "$prolog TOMCAT_VERSION: $TOMCAT_VERSION" >&2
#
export APACHE_APR_VERSION="${APACHE_APR_VERSION:-"1.7.6-1"}"
loggy "$prolog APACHE_APR_VERSION: $APACHE_APR_VERSION"
#
#export OPENSSL_VERSION="3.5.0-4"
#loggy "OPENSSL_VERSION: $OPENSSL_VERSION"
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
    "$APACHE_APR_VERSION" \
    "$ADD_DEBUG_RPMS"

s3_get_olfs_ngap_distro \
  "$S3_BUILD_BUCKET" \
  "$DOCKER_DIR" \
  "$OLFS_VERSION" 2>&1

#s3_get_openssl_distro \
#    "$S3_BUILD_BUCKET" \
#    "$DOCKER_DIR" \
#    "$OPENSSL_VERSION" \
#    "$TARGET_OS" \
#    "$ADD_DEBUG_RPMS"
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

loggy "$prolog docker image ls -a: "
loggy "$(docker image ls -a)"

function ngap_el9_dnf_sanity_check() {
    local prolog="el9_dnf_sanity_check() -"
    set -e
    loggy "$HR"
    if test -n "$DEBUG_BUILD"
    then
        loggy "$prolog Sanity checking installed packages..."
        loggy "$prolog openssl is located here: $(which openssl)"
        loggy "$prolog openssl version: $(openssl version)"
        loggy "$(dnf -y info openssl)"
        loggy "$prolog openssl is installed."
        loggy "$HR"
        loggy "$prolog libtirpc info:"
        loggy "$(dnf -y info libtirpc)"
        loggy "$HR2"
        loggy "$prolog rpm -ql libtirpc: "
        rpm -ql libtirpc
        loggy "$HR"
        loggy "$prolog libtirpc-devel info:"
        dnf -y info libtirpc-devel
        loggy "$HR2"
        loggy "$prolog rpm -ql libtirpc-devel: "
        rpm -ql libtirpc-devel
        loggy "$HR"
        loggy "$prolog libuuid info:"
        dnf -y info libuuid
        loggy "$prolog libuuid-devel info:"
        dnf -y info libuuid-devel
        dnf clean all
    else
        loggy "$prolog Skipping Sanity Checks..."
    fi
    loggy "$HR"
}