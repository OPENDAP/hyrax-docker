#!/bin/bash


HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

#########################################################################################################
# check_version()
#     Verify that we have the expected server version
function check_version() {
    local prolog="check_version() -"
    loggy "$HR0"
    loggy "$prolog BEGIN"

    local d_id="$1"
    if test -z "$d_id"; then
        loggy "$prolog ERROR! You must pass valid docker id as parameter 1"
        return 1
    fi
    loggy "$prolog                   d_id: $d_id"

    local deployment_context="$2"
    if test -z "$deployment_context"; then
        loggy "$prolog ERROR! You must pass a Hyrax deployment context  string as parameter 3"
        return 2
    fi
    loggy "$prolog     deployment_context: $deployment_context"

    local expected_version_str="$HYRAX_WEB_UI_VERSION"
    local docker_version_label
    local docker_labels
    local docker_version_status
    local status


    loggy "$prolog Checking docker image metadata for correct Hyrax version..."
    docker_labels="$(docker inspect --format="{{ index .Config.Labels}}" "$d_id")"
    loggy "$prolog docker_labels:"
    loggy "$docker_labels"
    loggy ""

    local version_label_key="org.opendap.hyrax.version"
    if test "$DOCKER_NAME" = "besd"
    then
        version_label_key="org.opendap.besdaemon.version"
        expected_version_str="$BES_VERSION"
    fi
    loggy "$prolog    version_label_key: $version_label_key"
    loggy "$prolog expected_version_str: $expected_version_str"

    docker_version_label="$(docker inspect --format="{{ index .Config.Labels \"$version_label_key\" }}" "$d_id")"
    docker_version_status=$?
    loggy "docker_version_label: '$docker_version_label'"
    if test "$expected_version_str" = "$docker_version_label"; then
        loggy "$prolog SUCCESS!
        The 'docker inspect' command for $d_id returned the expected_version_str value."
    else
        loggy "$prolog ERROR!
        The value of the hyrax version string '$docker_version_label' found in the docker
        inspect response does not match the expected_version_str env value '$expected_version_str'
        in this production environment!"
        return 1
    fi

    local some_page
    if test "$DOCKER_NAME" = "ngap"
    then
        loggy "$HR1"
        loggy "$prolog Checking NGAP landing page for correct Hyrax version."
        some_page="$(docker exec -it $d_id bash -c "cat /usr/share/tomcat/webapps/$deployment_context/docs/ngap/ngap.html")"
        # loggy "$prolog NGAP Landing Page: "
        # loggy "$some_page"
        echo "$some_page" | grep "$expected_version_str"
        status=$?
        if test $status -ne 0
        then
            loggy "$prolog ERROR! The expected version string as not found in the NGAP landing page."
            return  $status
        fi
    fi

    if test $DOCKER_NAME != "besd"
    then
        #####################################################################
        # Check version.xsl
        #
        loggy "$HR1"
        loggy "$prolog Checking version.xsl for correct Hyrax version, d_id: $d_id"
        some_page="$(docker exec -it "$d_id" bash -c "cat /usr/share/tomcat/webapps/$deployment_context/xsl/version.xsl")"
        #loggy "$prolog version.xsl: "
        #loggy "$some_page"
        echo "$some_page" | grep "$expected_version_str"
        status=$?
        if test $status -ne 0
        then
            loggy "$prolog ERROR! The expected version string as not found in the version.xsl file."
            return  $status
        fi
    fi
    loggy "$prolog END"
    loggy "$HR0"
    return 0
}

#
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
    sleep 10

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
        loggy "$prolog Success: Image '$image_tag' did not crash on startup"

        check_version "travis_test_image" "ROOT" "$HYRAX_WEB_UI_VERSION"
        status=$?
        if test $status -ne 0
        then
            loggy "$prolog ERROR! Version check failed. status: $status"
            return $status
        fi
        docker rm -f travis_test_image
    fi
    loggy "$prolog END"
    loggy "$HR0"
    return 0
}


test_startup $1
