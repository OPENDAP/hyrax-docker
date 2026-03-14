#!/bin/bash
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

###########################################################################
# tag_this_build()
tag_this_build() {
    local prolog="tag_this_build() -"
    local tag_name

    loggy "$prolog BEGIN"
    if [[ "$TRAVIS_BRANCH" == "master" && "$TRAVIS_PULL_REQUEST" != "false" ]]; then
        loggy "$prolog OS_BUILD_VERSION_TAG is '$OS_BUILD_VERSION_TAG'" >&2
        tag_name="${OS_BUILD_VERSION_TAG//:/@}"
        loggy "$prolog             tag_name is '$tag_name'" >&2
    #    git tag -a "$tag_name" -m "$(cat $TRAVIS_BUILD_DIR/travis-build-recipe)"; \
    #    git push origin "$tag_name"
    else
        loggy "$prolog Skipping Build Tag. TRAVIS_BRANCH $TRAVIS_BRANCH, TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST " >&2
    fi
    loggy "$prolog END"
}

tag_this_build