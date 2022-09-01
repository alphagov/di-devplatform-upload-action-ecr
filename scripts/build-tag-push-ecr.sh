#! /bin/bash

set -eu

echo "building image(s)"

cd "$WORKING_DIR"
echo "Packaging app in /$WORKING_DIR"

docker build -t "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA" .
docker push "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"
cosign sign --key "awskms:///${CONTAINER_SIGN_KMS_KEY_ARN}" "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"

sam package --template-file="$TEMPLATE_FILE" --s3-bucket="$ARTIFACT_BUCKET_NAME" --output-template-file=cf-template.yaml

sed -i "s|CONTAINER-IMAGE-PLACEHOLDER|$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA|" cf-template.yaml
zip template.zip cf-template.yaml
aws s3 cp template.zip "s3://$ARTIFACT_BUCKET_NAME/template.zip" --metadata "repository=$GITHUB_REPOSITORY,commitsha=$GITHUB_SHA"
