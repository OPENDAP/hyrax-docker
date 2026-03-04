#!/bin/bash
#
# Upload the results of tests after running a build on Travis
HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}

function upload_test_result() {
    local prolog="upload_test_result() -"
    loggy "$HR0"
    loggy "$prolog BEGIN"

    local docker_name="$1"
    loggy "$prolog docker_name: $docker_name"

    local log_file_name="$2"
    loggy "$prolog log_file_name: $log_file_name"

    if test -n "$docker_name" -o -n "$log_file_name"
    then
        if test "$docker_name" = "hyrax"; then
            # using: 'test -z "$AWS_ACCESS_KEY_ID" || ...' keeps after_script from running
            # the aws cli for forked PRs (where secure env vars are null). I could've used
            # an 'if' to block out the whole script, but I didn't... jhrg 3/21/18

            test -z "$AWS_ACCESS_KEY_ID" || aws s3 cp "/tmp/$log_file_name" s3://opendap.travis.tests/
        fi
    else
        echo "$prolog Missing docker_name or log_file_name name, SKIPPING. (docker_name: '$docker_name' log_file_name: '$log_file_name')"
    fi
    loggy "$prolog END"
}

upload_test_result "$1" "$2"