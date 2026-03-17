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

        loggy "$prolog Tagging local '$repo_name' repository"
        git tag -a "$tag_name" -m "Testing tag and push."

        status=$?
        if test $status -ne 0
        then
           loggy "$prolog Failed to tag repo."
           return $status
        else
            loggy "$prolog Tag operation succeeded."
        fi


        loggy "$prolog Setting git user.email"
        git config --global user.email "npotter@opendap.org"
        status=$?
        if test $status -ne 0
        then
           loggy "$prolog Failed to git config --global user.email \"npotter@opendap.org\""
           return $status
        else
            loggy "$prolog git config user.email succeeded."
        fi

        loggy "$prolog Setting git user.name"
        git config --global user.name "The Robot Travis"
        status=$?
        if test $status -ne 0
        then
           loggy "$prolog Failed to git config --global user.name \"The Robot Travis\""
           return $status
        else
            loggy "$prolog git config user.name succeeded."
        fi

        # Add
        # 2. Add the remote using the token
        # The PAT token is injected into the URL for authentication
        loggy "$prolog Injecting PAT token for $repo_name"
        git remote add origin-auth "https://${GIT_TOKEN}@github.com/OPENDAP/$repo_name.git" >&2
        if test $status -ne 0
        then
           loggy "$prolog Failed to git remote add origin-auth 'https://TOKEN@github.com/OPENDAP/$repo_name.git'"
           return $status
        else
            loggy "$prolog The 'git remote add origin-auth https://TOKEN@github.com/OPENDAP/$repo_name.git' command succeeded."
        fi

        loggy "$prolog Running 'git config --list'"
        loggy "$(git config --list)"
        status=$?
        if test $status -ne 0
        then
           loggy "$prolog The 'git config --list' failed."
           return $status
        else
            loggy "$prolog The 'git config --list' succeeded."
        fi
        loggy "$prolog "
        loggy "$prolog Pushing tag '$tag_name' to GitHub."
        set -x
        git push origin-auth HEAD:main "$tag_name"
        # git push "https://${GIT_TOKEN}@github.com/OPENDAP/$repo_name.git" "$tag_name"
        # git push "https://${GIT_UID}:${GIT_TOKEN}@github.com/OPENDAP/$repo_name.git" "$tag_name"
        # git push "$tag_name"
        status=$?
        set +x
        if test $status -ne 0
        then
           loggy "$prolog The 'git push' attempt failed."
           return $status
        else
            loggy "$prolog "
            loggy "$prolog "
            loggy "$prolog "
            loggy "$prolog The 'git push' command. succeeded."
        fi
    else
        loggy "$prolog Skipping Build Tag. TRAVIS_BRANCH: $TRAVIS_BRANCH, TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST "
    fi
    loggy "$prolog END"
}


tag_this_build
exit $?









