#!/bash/bash

tag_this_build() {
    local prolog="tag_this_build() -"
    local tag_name

    logg "$prolog BEGIN"
    if test "$TRAVIS_BRANCH" = "master"; then
       echo "$prolog OS_BUILD_VERSION_TAG is '$OS_BUILD_VERSION_TAG'" >&2
       tag_name="${OS_BUILD_VERSION_TAG//:/@}"
       echo "$prolog             tag_name is '$tag_name'" >&2
    #    git tag -a "$tag_name" -m "$(cat $TRAVIS_BUILD_DIR/travis-build-recipe)"; \
    #    git push origin "$tag_name"
    else
       echo "$prolog TRAVIS_BRANCH is not 'master', Skipping Build Tag" >&2
    fi
    logg "$prolog END"
}

tag_this_build