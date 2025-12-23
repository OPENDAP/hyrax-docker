#!/bin/bash
#
# Called from the travis.yml. This depends on env vars set by the 
# travis yaml. jhrg 3/31/21
set -e

PUSH_TO_ECR=""

echo "Logging into Docker Hub"
echo $DOCKER_HUB_PSWD | docker login -u $DOCKER_HUB_UID --password-stdin

echo "Pushing ${SNAPSHOT_IMAGE_TAG} to Docker Hub"
docker push ${SNAPSHOT_IMAGE_TAG}
echo "Pushing  ${BUILD_VERSION_TAG} to Docker Hub"
docker push ${BUILD_VERSION_TAG}

echo "Docker Hub deployment complete."

if test -n "$PUSH_TO_ECR"
then
    OPENDAP_AWS_ACCOUNT=747931985039

    echo "AWS configuration: "
    aws configure list

    echo "Pushing ${SNAPSHOT_IMAGE_TAG} to AWS ECR"
    docker tag ${SNAPSHOT_IMAGE_TAG} ${OPENDAP_AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${SNAPSHOT_IMAGE_TAG}
    docker push ${OPENDAP_AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${SNAPSHOT_IMAGE_TAG}

    echo "AWS ECR deployment complete."
else
    echo "No image pushed to ECR"
fi