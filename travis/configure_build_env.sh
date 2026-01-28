#!/bin/bash
HR="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
prolog="configure_build_env.sh -"
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

export TARGET_OS=$(grep "TARGET_OS: " ${VERSION_FILE} | awk '{print $2;}')
loggy "$prolog S3_BUILD_BUCKET: $S3_BUILD_BUCKET"
