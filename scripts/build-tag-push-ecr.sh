#! /bin/bash

set -eu

echo "building image(s)"

cd "${WORKING_DIRECTORY}"
echo "Packaging app in /$WORKING_DIRECTORY"

docker build -t "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA" .
docker push "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"
cosign sign --key "awskms:///${CONTAINER_SIGN_KMS_KEY_ARN}" "$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA"

echo "Running sam build on template file"
sam build --template-file="$TEMPLATE_FILE"
mv .aws-sam/build/template.yaml cf-template.yaml

if grep -q "CONTAINER-IMAGE-PLACEHOLDER"; then
  echo "Replacing \"CONTAINER-IMAGE-PLACEHOLDER\" with new ECR image ref"
  sed -i "s|CONTAINER-IMAGE-PLACEHOLDER|$ECR_REGISTRY/$ECR_REPO_NAME:$GITHUB_SHA|" cf-template.yaml
else
  echo "WARNING!!! Image placeholder text \"CONTAINER-IMAGE-PLACEHOLDER\" not found - uploading template anyway"
fi
zip template.zip cf-template.yaml
aws s3 cp template.zip "s3://$ARTIFACT_BUCKET_NAME/template.zip" --metadata "repository=$GITHUB_REPOSITORY,commitsha=$GITHUB_SHA"
