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
    if [[ "$TRAVIS_BRANCH" == "master" ]] # && "$TRAVIS_PULL_REQUEST" == "false" ]]
    then
        loggy "$prolog Tagging Build. TRAVIS_BRANCH: $TRAVIS_BRANCH, TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST "
        loggy "$prolog OS_BUILD_VERSION_TAG: '$OS_BUILD_VERSION_TAG' GITUID: $GITUID"
        tag_name="${OS_BUILD_VERSION_TAG//:/@}"
        #loggy "$prolog             tag_name: '$tag_name'"
        # git tag -a "$tag_name" -m "$(cat $TRAVIS_BUILD_DIR/travis-build-recipe)"

        tag_name="DEBUG-FTW-$TRAVIS_BUILD_NUMBER"
        loggy "$prolog             tag_name: '$tag_name'"


        git tag -a "$tag_name" -m "Testing tag and push."
        status=$?
        if $status -ne 0
        then
           loggy "$prolog Failed to rag repo."
           return $status
        fi

        git config --global user.email "npotter@opendap.org"
        status=$?
        if $status -ne 0
        then
           loggy "$prolog Failed to git config --global user.email \"npotter@opendap.org\""
           return $status
        fi
        git config --global user.name "The Robot Travis"
        status=$?
        if $status -ne 0
        then
           loggy "$prolog Failed to git config --global user.name \"The Robot Travis\""
           return $status
        fi
        # Add
        # 2. Add the remote using the token
        # The PAT token is injected into the URL for authentication
        git remote add origin-auth https://${GIT_TOKEN}@github.com/OPENDAP/$repo_name.git >&2
        if $status -ne 0
        then
           loggy "$prolog Failed to git remote add origin-auth STUFF"
           return $status
        fi

        git push origin-auth HEAD:main "$tag_name"
        #git push "https://${GIT_TOKEN}@github.com/OPENDAP/$repo_name.git" "$tag_name"
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
exit $?









