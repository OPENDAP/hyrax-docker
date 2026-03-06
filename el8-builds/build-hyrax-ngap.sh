#!/bin/bash
#
#
source  "./build-$TARGET_OS"
HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
prolog="build-hyrax-ngap.sh"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "# " prolog " - " $0;}' >&2
}
loggy "$HR0"
loggy "BEGIN"

export DOCKER_NAME="${DOCKER_NAME:-"ngap"}"
loggy "DOCKER_NAME: $DOCKER_NAME"

###############################################################################################
#export SNAPSHOT_IMAGE_TAG="${SNAPSHOT_IMAGE_TAG:-"opendap/hyrax:$DOCKER_NAME-snapshot-$TARGET_OS$TEST_DEPLOYMENT"}"
loggy "   SNAPSHOT_IMAGE_TAG: '$SNAPSHOT_IMAGE_TAG'" >&2
loggy "OS_SNAPSHOT_IMAGE_TAG: '$OS_SNAPSHOT_IMAGE_TAG'" >&2
#
#export BUILD_VERSION_TAG="${BUILD_VERSION_TAG:-"opendap/hyrax:$DOCKER_NAME-$HYRAX_VERSION-$TARGET_OS$TEST_DEPLOYMENT"}"
loggy "    BUILD_VERSION_TAG: '$OS_BUILD_VERSION_TAG'" >&2
loggy " OS_BUILD_VERSION_TAG: '$OS_BUILD_VERSION_TAG'" >&2
###############################################################################################

loggy "TOMCAT_MAJOR_VERSION: $TOMCAT_MAJOR_VERSION" >&2
export TOMCAT_VERSION=
TOMCAT_VERSION="$(get_latest_tomcat_version_number "$TOMCAT_MAJOR_VERSION")"
loggy "TOMCAT_VERSION: $TOMCAT_VERSION" >&2

show_version

get_tomcat_distro "$DOCKER_NAME" "$TOMCAT_VERSION"

get_ngap_olfs_distro "$S3_BUILD_BUCKET" "$DOCKER_NAME" "$OLFS_VERSION" 2>&1

docker build \
    --build-arg TOMCAT_VERSION \
    --build-arg RELEASE_DATE \
    --build-arg HYRAX_VERSION \
    --build-arg LIBDAP_VERSION \
    --build-arg BES_VERSION \
    --build-arg OLFS_VERSION \
    --build-arg BES_CORE_IMAGE_TAG \
    --tag "$OS_SNAPSHOT_IMAGE_TAG" \
    --tag "$OS_BUILD_VERSION_TAG" \
    "$DOCKER_NAME"

docker image ls -a

loggy "END"
loggy "$HR0"
