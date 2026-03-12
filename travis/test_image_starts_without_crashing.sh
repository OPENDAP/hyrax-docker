#!/bin/bash
#
# Confirm that image launches without crashing at startup

function test_startup() {
    local image_tag="$1"

    echo "# Test that image does not crash on startup"
    docker run -d --name=travis_test_image "${image_tag}"
    
    # Wait to give the entrypoint script/application a chance to run
    sleep 10

    # The launched image should be running; if it is not, it must have crashed 
    # at startup. This will show up as an `Exited` message in `docker ps`
    local any_images_crashed=$(docker ps -a | grep travis_test_image | grep Exited)
    if [ -n "$result" ]; then
        echo "# Error: Image ${image_tag} failed at startup\n"
        docker ps -a
        echo "\n# Logs from failing test instance: \n"
        docker logs travis_test_image

        # Wait to give the logs a chance to print out before we exit
        sleep 10
        exit 1
    else
        echo "# Success: Image '${image_tag}' did not crash on startup"
        docker rm -f travis_test_image
    fi
}

test_startup $1
