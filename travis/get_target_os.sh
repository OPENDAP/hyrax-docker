#!/bin/bash
HR="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
prolog="get_target_os.sh -"
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

export TARGET_OS=$(grep "TARGET_OS: " "${VERSION_FILE}" | awk '{print $2;}')
loggy "$prolog TARGET_OS: $TARGET_OS"
echo "$TARGET_OS"