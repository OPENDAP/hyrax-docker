#!/bin/bash
#
# When the release numbers are edited in configure.ac, update this
# to the current Travis number so that the 'build number' in
# x.y.z-<build number> is zero. jhrg 3/22/21
#
HR="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# version_and_build_offsets.sh() - "$0;}' >&2
}

loggy "BEGIN $HR"

# This is the current Hyrax release version
export HYRAX_RELEASE_VERSION=1.18.0
loggy "HYRAX_RELEASE_VERSION: $HYRAX_RELEASE_VERSION" >&2

# This is the TravisCI build number when the
# last formal hyrax release was built.
export TRAVIS_HYRAX_BUILD_OFFSET=3884

if [ "$TRAVIS_PULL_REQUEST" != "false" ]
then
  loggy "This is a Pull Request build for PR #$TRAVIS_PULL_REQUEST"
  loggy "Setting TRAVIS_HYRAX_BUILD_OFFSET to 0"
  TRAVIS_HYRAX_BUILD_OFFSET=0
fi

loggy "Using TRAVIS_HYRAX_BUILD_OFFSET: $TRAVIS_HYRAX_BUILD_OFFSET"
loggy "END $HR"


