#!/bin/bash
#
# Called from the travis.yml. This depends on env vars set by the 
# travis yaml. jhrg 3/31/21
HR0="#######################################################################"
HR1="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
HR2="--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
#############################################################################
# loggy()
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}
prolog="$0() -"
loggy "$HR0"
loggy "$prolog BEGIN"

set -e

OPENDAP_AWS_ACCOUNT=747931985039

loggy "$prolog Logging into Docker Hub"
echo "$DOCKER_HUB_PSWD" | docker login -u "$DOCKER_HUB_UID" --password-stdin

loggy "$HR1"
loggy "$prolog Deploying $SNAPSHOT_IMAGE_TAG to Docker Hub"
docker push "$SNAPSHOT_IMAGE_TAG"
loggy "$HR2"
loggy "$prolog Deploying $BUILD_VERSION_TAG to Docker Hub"
docker push "$BUILD_VERSION_TAG"
loggy "$HR2"
loggy "$prolog Docker Hub deployment complete."
loggy "$HR1"

loggy "$prolog AWS configuration: "
loggy "$(aws configure list)"
#loggy "$prolog Deploying ${SNAPSHOT_IMAGE_TAG} to AWS ECR"
#docker tag "$SNAPSHOT_IMAGE_TAG" "$OPENDAP_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$SNAPSHOT_IMAGE_TAG"
#docker push "$OPENDAP_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$SNAPSHOT_IMAGE_TAG"
#loggy "$prolog AWS ECR deployment complete."


loggy "$prolog END"
loggy "$HR0"
