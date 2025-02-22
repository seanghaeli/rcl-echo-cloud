#!/bin/bash
if [[ ! -n "$1" ]]; then
    GITBRANCH="master"
else
    GITBRANCH=$1
fi

echo "Using GIT BRANCH: $GITBRANCH"

cd ../layers
./createLayer.sh

cd ../lambdas

BUCKET=$(aws ssm get-parameter --name "/rcl-echo-cloud/${GITBRANCH}/s3Bucket" --query Parameter.Value --output text)
echo "Bucket: ${BUCKET}"

sam package --s3-bucket $BUCKET --output-template-file out.yaml
sam deploy --template-file out.yaml --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name rcl-echo-cloud-lambda --parameter-overrides ParameterKey=gitHubBranch,ParameterValue=$GITBRANCH

LAMBDAARN=$(aws ssm get-parameter --name "/rcl-echo-cloud/${GITBRANCH}/lambdaArn" --query Parameter.Value --output text)
echo "Lambda: ${LAMBDAARN}"

cp notification.json notification.s3 
sed "s|%LambdaArn%|$LAMBDAARN|g" notification.json > notification.s3

echo "Configuring s3Event"
aws s3api put-bucket-notification-configuration --bucket ${BUCKET} --notification-configuration file://notification.s3
rm notification.s3
rm ../layers/*.zip
rm out.yaml