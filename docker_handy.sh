#!/bin/bash
# Docker Tricks
# Source this file and read it to see what's up.
# And then use the functions on the command line
#


#
# Stop all running containers
#
function dhalt() {
    docker stop $(docker ps -aq);
}

#
# Remove all containers
#
function drmc(){
    docker rm $(docker ps -aq);
}

#
# Remove all images
#
function drmi(){
    docker rmi $(docker images -q);
}

#
# List all containers (only IDs)
#
function dlist(){
    docker ps -aq;
}

#
# Interactive Login Shell
#
function dlogin(){
   docker exec -ti $1 bash;
} 

#
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