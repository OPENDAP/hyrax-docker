#!/bin/bash
#
# Called from the travis.yml. This depends on env vars set by the 
# travis yaml. jhrg 3/31/21
HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
prolog="deploy_to_docker_hub.sh"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "# " prolog " - " $0;}' >&2
}
loggy "$HR0"
loggy "BEGIN"

set -e

loggy "Logging into Docker Hub"
echo "$DOCKER_HUB_PSWD" | docker login -u "$DOCKER_HUB_UID" --password-stdin
loggy "$HR1"

loggy "Running 'docker image ls -a'"
loggy "$(docker image ls -a)"
loggy "$HR2"


loggy "Deploying '$OS_SNAPSHOT_IMAGE_TAG' to Docker Hub"
docker push "$OS_SNAPSHOT_IMAGE_TAG"
loggy "$HR2"

if test -n "$SNAPSHOT_IMAGE_TAG"
then
    loggy "Tagging $OS_SNAPSHOT_IMAGE_TAG as $SNAPSHOT_IMAGE_TAG"
    docker tag "$OS_SNAPSHOT_IMAGE_TAG" "$SNAPSHOT_IMAGE_TAG"
    loggy "Deploying '$SNAPSHOT_IMAGE_TAG' to Docker Hub"
    docker push "$SNAPSHOT_IMAGE_TAG"
    loggy "$HR2"
fi

loggy "Deploying '$OS_BUILD_VERSION_TAG' to Docker Hub"
docker push "$OS_BUILD_VERSION_TAG"
loggy "$HR2"

if test -n "$BUILD_VERSION_TAG"
then
    loggy "Tagging $OS_BUILD_VERSION_TAG as $BUILD_VERSION_TAG"
    docker tag "$OS_BUILD_VERSION_TAG" "$BUILD_VERSION_TAG"
    loggy "Deploying '$BUILD_VERSION_TAG' to Docker Hub"
    docker push "$BUILD_VERSION_TAG"
    loggy "$HR2"
fi

loggy "Docker Hub deployment complete."
loggy "$HR1"



loggy "AWS configuration: "
loggy "$(aws configure list)"
#loggy "Deploying ${SNAPSHOT_IMAGE_TAG} to AWS ECR"
#docker tag "$SNAPSHOT_IMAGE_TAG" "$OPENDAP_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$SNAPSHOT_IMAGE_TAG"
#docker push "$OPENDAP_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$SNAPSHOT_IMAGE_TAG"
#loggy "AWS ECR deployment complete."


loggy "END"
loggy "$HR0"
