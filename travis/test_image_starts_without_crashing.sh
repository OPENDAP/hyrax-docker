#!/bin/bash


HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}

function check_image_labels(){
    local prolog="check_image_labels() -"
    loggy "$HR0"
    loggy "$prolog BEGIN"

    local d_id="$1"
    local label_key="$2"
    local expected_value="$3"

    local docker_labels
    local status

    loggy "$prolog Retrieving docker image metadata for correct Hyrax version..."
    docker_labels="$(docker inspect --format="{{ index .Config.Labels}}" "$d_id")"
    loggy "$prolog docker_labels:"
    loggy "$docker_labels"
    loggy ""

    loggy "$prolog Checking the value of label '$label_key' from docker image '$d_id' metadata..."
    key_value="$(docker inspect --format="{{ index .Config.Labels \"$label_key\" }}" "$d_id")"
    loggy "key_value: '$key_value'"
    if test "$expected_value" = "$key_value"; then
        loggy "$prolog SUCCESS!
        The 'docker inspect' command for $d_id returned the expected_value string."
    else
        loggy "$prolog ERROR!
        The value of the the docker label '$label_key' found in the docker
        inspect response does not match the expected_value '$expected_value'
        in this production environment!"
        return 1
    fi
}

function check_file_in_image() {
    local prolog="check_file_in_image() -"
    loggy "$HR0"
    loggy "$prolog BEGIN"

    local d_id="$1"
    local file_path="$2"
    local expected_value="$3"

    local status
    local some_page

    loggy "$HR1"
    loggy "$prolog Checking for $expected_value' in '$d_id:$file_path'"
    some_page="$(docker exec -it "$d_id" bash -c "cat \"$file_path\"")"
    # loggy "$prolog NGAP Landing Page: "
    # loggy "$some_page"
    echo "$some_page" | grep "$expected_value"
    status=$?
    if test $status -ne 0
    then
        loggy "$prolog ERROR! The expected value '$expected_value' was not found in the file '$file_path'"
        return  $status
    fi
    return 0
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
    local status
    local some_page



    local version_label_key="org.opendap.hyrax.version"
    if test "$DOCKER_NAME" = "besd"
    then
        version_label_key="org.opendap.besdaemon.version"
        expected_version_str="$BES_VERSION"
    fi
    loggy "$prolog    version_label_key: $version_label_key"
    loggy "$prolog expected_version_str: $expected_version_str"


    check_image_labels "$d_id" "$version_label_key" "$expected_version_str"
    status=$?
    if test $status -ne 0
    then
        loggy "$prolog ERROR! The expected version string was not found in the docker image metadata."
        return  $status
    fi


    if test "$DOCKER_NAME" = "ngap"
    then
        check_file_in_image "$d_id" "/usr/share/tomcat/webapps/$deployment_context/docs/ngap/ngap.html" "$expected_version_str"
        if test $status -ne 0
        then
            loggy "$prolog ERROR! The expected version string was not found in the file."
            return  $status
        fi
    fi

    if test $DOCKER_NAME != "besd"
    then
        check_file_in_image "$d_id" "/usr/share/tomcat/webapps/$deployment_context/xsl/version.xsl" "$expected_version_str"
        if test $status -ne 0
        then
            loggy "$prolog ERROR! The expected version string was not found in the file."
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
