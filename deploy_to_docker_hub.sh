#!/bin/bash
#
# Called from the travis.yml. This depends on env vars set by the 
# travis yaml. jhrg 3/31/21
set -e

OPENDAP_AWS_ACCOUNT=747931985039

echo "Deploying ${SNAPSHOT_IMAGE_TAG} to Docker Hub"
echo $DOCKER_HUB_PSWD | docker login -u $DOCKER_HUB_UID --password-stdin

docker push ${SNAPSHOT_IMAGE_TAG}
docker push ${BUILD_VERSION_TAG}

echo "Docker Hub deployment complete."

echo "Deploying ${SNAPSHOT_IMAGE_TAG} to AWS ECR"
aws configure list

docker tag ${SNAPSHOT_IMAGE_TAG} ${OPENDAP_AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${SNAPSHOT_IMAGE_TAG}
docker push ${OPENDAP_AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${SNAPSHOT_IMAGE_TAG}

echo "AWS ECR deployment complete."