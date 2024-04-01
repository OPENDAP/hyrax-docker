#!/bin/bash
BUILD_DIR=${BUILD_DIR:-"./builds"}
export S3_BUILD_BUCKET=${S3_BUILD_BUCKET:-"opendap.travis.build"}
export ADD_DEBUG_RPMS=${ADD_DEBUG_RPMS:-"true"}

echo "# build_from_s3_binaries ####################################################" >&2

start_dir=$(pwd)
echo "# BUILD_RECIPE: ${BUILD_RECIPE}" >&2

cd "${BUILD_DIR}" || exit
#
# The build-rh8 script contains a library of bash functions
# to do the many things, like retrieving binaries from s3 or www.opendap.org
# building docker images from said files, etc.build
#
source ./build-rh8 "${BUILD_RECIPE}"

export TOMCAT_VERSION=$(get_latest_tomcat_version_number "${TOMCAT_MAJOR_VERSION}")
show_version

build_hyrax
