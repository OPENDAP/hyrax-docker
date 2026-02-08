#!/bin/bash
#
# Upload the results of tests after running a build on Travis

function upload_test_result() {
    local docker_name="$1"
    local log_file_name="$2"

    if test "$docker_name" = "hyrax"; then
        # using: 'test -z "$AWS_ACCESS_KEY_ID" || ...' keeps after_script from running
        # the aws cli for forked PRs (where secure env vars are null). I could've used
        # an 'if' to block out the whole script, but I didn't... jhrg 3/21/18

        test -z "$AWS_ACCESS_KEY_ID" || aws s3 cp "/tmp/$log_file_name" s3://opendap.travis.tests/
    fi

}