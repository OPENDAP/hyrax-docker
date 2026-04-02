#!/bin/bash

HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

#############################################################################
# Confirm that image launches without crashing at startup
function test_startup() {
    local prolog="test_startup() -"
    loggy "$HR0"
    loggy "$prolog BEGIN"
    local image_tag="$1"
    local any_images_crashed
    local status

    loggy "$prolog Test that image does not crash on startup"
    docker run -d --name=travis_test_image "$image_tag"

    # Wait to give the entrypoint script/application a chance to run
    local wait_seconds=10
    loggy "$prolog Waiting for $wait_seconds to ensure that '$image_tag' has a chance to start."
    sleep $wait_seconds

    # The launched image should be running; if it is not, it must have crashed
    # at startup. This will show up as an `Exited` message in `docker ps`
    any_images_crashed=$(docker ps -a | grep travis_test_image | grep Exited)
    if [ -n "$result" ]; then
        loggy "$prolog Error: Image '$image_tag' failed at startup"
        docker ps -a
        loggy "$prolog Logs from failing test instance: "
        loggy "$(docker logs travis_test_image)"

        # Wait to give the logs a chance to print out before we exit
        sleep 10
        exit 1
    else
        loggy "$prolog Success: Image '$image_tag' did not crash on startup."
        loggy "$prolog Docker logs:"
        loggy "$(docker logs travis_test_image)"
        loggy ""
        loggy ""
        loggy ""
        docker rm -f travis_test_image
    fi
    loggy "$prolog END"
    loggy "$HR0"
    return 0
}

test_startup "$1"
