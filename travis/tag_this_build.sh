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
    local status
    local repo_name="hyrax-docker"

    loggy "$prolog BEGIN"
    if [[ "$TRAVIS_BRANCH" == "master" && "$TRAVIS_PULL_REQUEST" == "false" ]]
    then
        loggy "$prolog Tagging Build. TRAVIS_BRANCH: $TRAVIS_BRANCH, TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST "
        loggy "$prolog OS_BUILD_VERSION_TAG: '$OS_BUILD_VERSION_TAG' GITUID: $GITUID"
        tag_name="${OS_BUILD_VERSION_TAG//:/@}"
        loggy "$prolog             tag_name: '$tag_name'"
        # git tag -a "$tag_name" -m "$(cat $TRAVIS_BUILD_DIR/travis-build-recipe)"

        tag_name="DEBUG-FTW-$TRAVIS_BUILD_NUMBER"
        git tag -a "$tag_name" -m "Testing tag and push."

        git push "https://${GIT_PSWD}@github.com/OPENDAP/$repo_name.git" "$tag_name"
        status=$?
        if $status -ne 0
        then
           loggy "$prolog The 'git push attempt' failed."
           return $status
        fi
    else
        loggy "$prolog Skipping Build Tag. TRAVIS_BRANCH: $TRAVIS_BRANCH, TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST "
    fi
    loggy "$prolog END"
}


tag_this_build