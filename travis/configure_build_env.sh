#!/bin/bash
HR="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
prolog="configure_build_env.sh -"
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

loggy "$HR"
TARGET_OS="${1:-"el8"}"
loggy "$prolog TARGET_OS: $TARGET_OS"

export TOMCAT_MAJOR_VERSION=9
loggy "$prolog TOMCAT_MAJOR_VERSION: $TOMCAT_MAJOR_VERSION"

export VERSION_FILE="${TARGET_OS}-build-recipe"
loggy "$prolog VERSION_FILE: $VERSION_FILE"

export S3_BUILD_BUCKET="opendap.travis.build"
loggy "$prolog S3_BUILD_BUCKET: $S3_BUILD_BUCKET"

export LIBDAP_VERSION=$(grep "libdap4-" ${VERSION_FILE} | awk '{print $1;}' export | sed "s/libdap4-//g")
loggy "$prolog LIBDAP_VERSION: $LIBDAP_VERSION"

export BES_VERSION=$(grep "bes-" ${VERSION_FILE} | awk '{print $1;}' export | sed "s/bes-//g")
loggy "$prolog BES_VERSION: $BES_VERSION"

export HYRAX_VERSION=$(grep "hyrax-" ${VERSION_FILE} | awk '{print $1;}' export | sed "s/hyrax-//g")
loggy "$prolog HYRAX_VERSION: $HYRAX_VERSION"

export OLFS_VERSION=$(grep "olfs-" ${VERSION_FILE} | awk '{print $1;}' export | sed "s/olfs-//g")
loggy "$prolog OLFS_VERSION: $OLFS_VERSION"

export OLFS_DISTRO="olfs-${OLFS_VERSION}-webapp.tgz"
loggy "$prolog OLFS_DISTRO: $OLFS_DISTRO"

export OLFS_DISTRO_URL="s3://$S3_BUILD_BUCKET/${OLFS_DISTRO}"
loggy "$prolog OLFS_DISTRO_URL: $OLFS_DISTRO_URL"

export NGAP_DISTRO="ngap-${OLFS_VERSION}-webapp.tgz"
loggy "$prolog NGAP_DISTRO: $NGAP_DISTRO"

export NGAP_DISTRO_URL="s3://$S3_BUILD_BUCKET/${NGAP_DISTRO}"
loggy "$prolog NGAP_DISTRO_URL: $NGAP_DISTRO_URL"

export ROBOTS_DISTRO="robots-olfs-${OLFS_VERSION}-webapp.tgz"
loggy "$prolog ROBOTS_DISTRO: $ROBOTS_DISTRO"

export ROBOTS_DISTRO_URL="s3://$S3_BUILD_BUCKET/${ROBOTS_DISTRO}"
loggy "$prolog ROBOTS_DISTRO_URL: $ROBOTS_DISTRO_URL"

export LIBDAP_RPM_NAME="libdap-${LIBDAP_VERSION}.${TARGET_OS}.x86_64.rpm"
loggy "$prolog LIBDAP_RPM_NAME: $LIBDAP_RPM_NAME"

export LIBDAP_RPM_URL="s3://$S3_BUILD_BUCKET/${LIBDAP_RPM_NAME}"
loggy "$prolog LIBDAP_RPM_URL: $LIBDAP_RPM_URL"

export BES_RPM_NAME="bes-${BES_VERSION}.static.${TARGET_OS}.x86_64.rpm"
loggy "$prolog BES_RPM_NAME: $BES_RPM_NAME"

export BES_RPM_URL="s3://$S3_BUILD_BUCKET/${BES_RPM_NAME}"
loggy "$prolog BES_RPM_URL: $BES_RPM_URL"

export ADD_DEBUG_RPMS=""
