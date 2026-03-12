#!/bin/bash
#
# When the release numbers are edited for a release, update these
# to the current Travis number so that the 'build number' in
# x.y.z-<build number> is zero.

export HYRAX_RELEASE_VERSION=1.17.1
export TRAVIS_HYRAX_BUILD_OFFSET=2410
echo "#     HYRAX_RELEASE_VERSION: $HYRAX_RELEASE_VERSION" >&2
echo "# TRAVIS_HYRAX_BUILD_OFFSET: $TRAVIS_HYRAX_BUILD_OFFSET" >&2
