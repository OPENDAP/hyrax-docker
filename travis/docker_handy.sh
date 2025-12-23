#!/bin/bash
################################################################################
#
# Handy Little Docker shortcuts.
#
# This file contains a collection of bash functions that can be used to
# reduce the typing associated with controlling Docker operations.
# For example drmac (docker rm all containers) will remove all of the
# dontainer in the docker engine.
#
# - Source this file into your working shell
# - Read this file to see the commands
# - And then use the functions defined herein
#   do the Docker things in your working shell.
#
#------------------------------------------------------------------------------


# - - - - - - - - - - - - - - - - - - - -
# Stop all running containers
#
function dhalt() {
    docker stop $(docker ps -aq);
}

# - - - - - - - - - - - - - - - - - - - -
# Remove all containers
#
function drmac(){
    docker rm -f $(docker ps -aq);
}

# - - - - - - - - - - - - - - - - - - - -
# Remove all images
#
function drmai(){
    docker rmi -f $(docker images -q);
}

# - - - - - - - - - - - - - - - - - - - -
# List all containers (only IDs)
#
function dlist(){
    docker ps -aq;
}

# - - - - - - - - - - - - - - - - - - - -
# Interactive Login Shell
#
# Uses the first argument as the id of the running container.
#
function dlogin(){
   docker exec -ti $1 bash;
} 

# - - - - - - - - - - - - - - - - - - - -
# stop, cleanup container and image, build, run, login interactive shell
#
function dscbrl() {
    package=$1;
    tag=`echo "${package}" | tr '[:upper:]' '[:lower:]'`
    docker container stop ${tag}
    docker rm $(docker ps -aq)
    docker rmi ${tag}
    docker build -t ${tag} ${package}
    docker run --name ${tag} -d -p 8080:8080 ${tag}
    docker exec -ti ${tag} bash
}
