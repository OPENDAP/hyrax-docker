#!/bin/bash
#
#
# We must assume that the shell has sourced ./build-el9 prior (in Travis) so that
# downstream Travis activities (like deployment) will have all the ENV vars they
# need to run.
source  "./build-$TARGET_OS" "$BUILD_RECIPE"
if test $? -ne 0; then
    echo "ERROR! Failed to source ./build-$TARGET_OS" >&2
    return 2
fi

HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
bhn_prolog="build-hyrax-ngap.sh[]"
function loggy(){
    echo  "$@" | awk -v prolog="$bhn_prolog" '{ print "# " prolog " - " $0;}' >&2
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
#
export APACHE_APR_VERSION="${APACHE_APR_VERSION:-"1.7.6-1"}"
loggy "APACHE_APR_VERSION: $APACHE_APR_VERSION"
#
#export OPENSSL_VERSION="3.5.0-4"
#loggy "OPENSSL_VERSION: $OPENSSL_VERSION"
#
show_version
#
loggy "Getting Tomcat distro..."
get_tomcat_distro "$DOCKER_NAME" "$TOMCAT_VERSION"

# @TODO Why are we getting Apache RPMs from OPeNDAP's build bucket? Why not lastest APR from Apache??
loggy "Getting Apache APR..."
s3_get_apache_apr_distro \
    "$S3_BUILD_BUCKET" \
    "$DOCKER_DIR" \
    "$APACHE_APR_VERSION" \
    "$ADD_DEBUG_RPMS"

loggy "Getting NGAP/OLFS distribution."
s3_get_olfs_ngap_distro \
  "$S3_BUILD_BUCKET" \
  "$DOCKER_DIR" \
  "$OLFS_VERSION" \
  "$TARGET_OS" 2>&1

loggy "Getting Redisson Jars."
loggy "$(gradle downloadRedisson)"
ls -l ./ngap/redission

# Make the HyraxVersion assets to be injected into the docker image.
make_hyrax_version_assets "$HYRAX_WEB_UI_VERSION"

set -e
docker build \
   --build-arg TOMCAT_VERSION \
   --build-arg RELEASE_DATE \
   --build-arg HYRAX_VERSION="$HYRAX_WEB_UI_VERSION" \
   --build-arg LIBDAP_VERSION \
   --build-arg BES_VERSION \
   --build-arg OLFS_VERSION \
   --build-arg BES_CORE_IMAGE_TAG \
   --build-arg OPENSSL_VERSION \
   --tag "${OS_SNAPSHOT_IMAGE_TAG}" \
   --tag "${OS_BUILD_VERSION_TAG}" \
   "${DOCKER_NAME}"
#
set +e

loggy "docker image ls -a: "
loggy "$(docker image ls -a)"

function ngap_el9_dnf_sanity_check() {
    local prolog="ngap_el9_dnf_sanity_check() -"
    set -e
    loggy "$HR0"
    if test -n "$DEBUG_BUILD"
    then
        loggy "$prolog Sanity checking installed packages..."
        loggy "$prolog openssl is located here: $(which openssl)"
        loggy "$prolog openssl version: $(openssl version)"
        loggy "$(dnf -y info openssl)"
        loggy "$prolog openssl is installed."
        loggy "$HR1"
        loggy "$prolog libtirpc info:"
        loggy "$(dnf -y info libtirpc)"
        loggy "$HR2"
        loggy "$prolog rpm -ql libtirpc: "
        rpm -ql libtirpc
        loggy "$HR1"
        loggy "$prolog libtirpc-devel info:"
        dnf -y info libtirpc-devel
        loggy "$HR2"
        loggy "$prolog rpm -ql libtirpc-devel: "
        rpm -ql libtirpc-devel
        loggy "$HR1"
        loggy "$prolog libuuid info:"
        dnf -y info libuuid
        loggy "$prolog libuuid-devel info:"
        dnf -y info libuuid-devel
        dnf clean all
    else
        loggy "$prolog Skipping Sanity Checks..."
    fi
    loggy "$HR0"
}