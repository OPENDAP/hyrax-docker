#!/bin/bash
HR="###########################################################################"
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

DEBUG_TAG_OPS=

###########################################################################
# tag_this_build()
tag_this_build() {
    local prolog="tag_this_build() -"
    local tag_name
    local status
    local repo_name="hyrax-docker"

    loggy "$HR"
    loggy "$prolog BEGIN"
    loggy "$prolog        TRAVIS_BRANCH: '$TRAVIS_BRANCH'"
    loggy "$prolog  TRAVIS_PULL_REQUEST: '$TRAVIS_PULL_REQUEST'"
    loggy "$prolog        DEBUG_TAG_OPS: '$DEBUG_TAG_OPS'"
    loggy "$prolog OS_BUILD_VERSION_TAG: '$OS_BUILD_VERSION_TAG'"
    if [[ "$TRAVIS_BRANCH" == "master" ]] && [[ "$TRAVIS_PULL_REQUEST" == "false" || -n "$DEBUG_TAG_OPS" ]]
    then
        # Check for a token...
        if test -z "$GIT_TOKEN"
        then
          echo "ERROR: Unable to tag build. The GIT_TOKEN is empty. Check your Travis settings or PR source."
          return 111
        fi

        if test -z "$DEBUG_TAG_OPS"
        then
            # Not debuggin? Then tag it for real.
            tag_name="${OS_BUILD_VERSION_TAG//:/@}"
            loggy "$prolog             tag_name: '$tag_name'"
            git tag -a "$tag_name" -m "$(cat $TRAVIS_BUILD_DIR/travis-build-recipe)"
        else
            # We're debuggin, use the debuggin tags
            tag_name="DEBUG-FTW-$TRAVIS_BUILD_NUMBER"
            loggy "$prolog DEBUG ----- tag_name: '$tag_name'"
            git tag -a "$tag_name" -m "Testing tag and push."
        fi
        status=$?
        if test $status -ne 0
        then
           loggy "$prolog ERROR(status: $status): Failed to tag repo."
           return $status
        else
            loggy "$prolog Tag operation succeeded."
        fi

        loggy "$prolog Setting git user.email"
        git config --global user.email "npotter@opendap.org"
        status=$?
        if test $status -ne 0
        then
           loggy "$prolog ERROR(status: $status): Failed to git config --global user.email \"npotter@opendap.org\""
           return $status
        else
            loggy "$prolog git config user.email succeeded."
        fi

        loggy "$prolog Setting git user.name"
        git config --global user.name "The Robot Travis"
        status=$?
        if test $status -ne 0
        then
           loggy "$prolog ERROR(status: $status): Failed to git config --global user.name \"The Robot Travis\""
           return $status
        else
            loggy "$prolog git config user.name succeeded."
        fi

        loggy "$prolog Rewrite the remote URL to include the PAT $repo_name"
        git remote set-url origin "https://${GIT_TOKEN}@github.com/OPENDAP/$repo_name.git" > /dev/null 2>&1
        if test $status -ne 0
        then
           loggy "$prolog ERROR(status: $status): Failed to 'git remote set-url origin https://TOKEN@github.com/OPENDAP/$repo_name.git'"
           return $status
        else
            loggy "$prolog The 'git remote set-url origin https://TOKEN@github.com/OPENDAP/$repo_name.git' command succeeded."
        fi

        if test -n "$DEBUG_TAG_OPS"
        then
            loggy "$prolog Running 'git config --list'"
            loggy "$(git config --list)"
            status=$?
            if test $status -ne 0
            then
               loggy "$prolog ERROR(status: $status): The 'git config --list' failed."
               return $status
            else
                loggy "$prolog The 'git config --list' succeeded."
            fi
        fi

        loggy "$prolog "
        loggy "$prolog Pushing tag '$tag_name' to GitHub."
        #set -x
        git push origin "$tag_name"
        status=$?
        #set +x
        if test $status -ne 0
        then
           loggy "$prolog ERROR(status: $status): The 'git push' attempt failed."
           return $status
        else
            loggy "$prolog "
            loggy "$prolog "
            loggy "$prolog The 'git push' command. succeeded."
            loggy "$prolog "
            loggy "$prolog "
        fi
    else
        loggy "$prolog Skipping Build Tag. TRAVIS_BRANCH: $TRAVIS_BRANCH, TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST "
    fi
    loggy "$prolog END"
    loggy "$HR"

}


tag_this_build
exit $?
