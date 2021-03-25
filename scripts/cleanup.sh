#!/bin/bash
set -ex

## Base tools
sudo yum update -y && sudo yum install -y mysql

### jq - yum install jq1.5 whereas, the walk command requires jq1.6
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
chmod +x jq
sudo mv jq /usr/local/bin

### kubectl
cd
mkdir bin && cd bin
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
chmod +x kubectl
export PATH=$PATH:$HOME/bin
cd

### eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

### helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | /bin/bash -

## Detach IAM policy
echo 'Detaching IAM policy for CloudWatch Agent'
EKS_CLUSTER=eks-saga-orchestration
STACK_NAME=eksctl-${EKS_CLUSTER}-nodegroup-ng-db
ROLE_NAME=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')

## Remove cluster objects, EKS cluster and ELB
export RDS_DB_ID=eks-saga-db
export EKS_VPC=`aws eks describe-cluster --name ${EKS_CLUSTER} --query 'cluster.resourcesVpcConfig.vpcId' --output text`
export RDS_VPC=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DBSubnetGroup.VpcId' --output text`

aws eks update-kubeconfig --name ${EKS_CLUSTER}

git clone ${GIT_URL}/amazon-eks-saga-orchestration-cluster
cd amazon-eks-saga-orchestration-cluster/scripts
./cleanup.sh ${STACK_NAME} ${ACCOUNT_ID} ${RDS_DB_ID} ${EKS_VPC} ${RDS_VPC} ${EKS_CLUSTER}
cd

## Remove RDS
git clone ${GIT_URL}/amazon-eks-saga-orchestration-db
export PROJECT_HOME=${PWD}/amazon-eks-saga-orchestration-db
# Use changed password !!
export MYSQL_MASTER_PASSWORD='V3ry.Secure.Passw0rd'
source ${PROJECT_HOME}/scripts/drop.sh
source ${PROJECT_HOME}/scripts/cleanup.sh ${ACCOUNT_ID} ${RDS_DB_ID}
cd

## Remove SNS-SQS, IAM and ECR
git clone ${GIT_URL}/amazon-eks-saga-orchestration-aws
cd amazon-eks-saga-orchestration-aws/scripts
./cleanup.sh ${REGION_ID} ${ACCOUNT_ID} O
./ciam.sh ${ACCOUNT_ID} O
./ecr.sh D

## Remove CloudWatch log groups
aws logs delete-log-group --log-group-name /aws/eks/${EKS_CLUSTER}/cluster
aws logs delete-log-group --log-group-name /aws/containerinsights/${EKS_CLUSTER}/application
aws logs delete-log-group --log-group-name /aws/containerinsights/${EKS_CLUSTER}/dataplane
aws logs delete-log-group --log-group-name /aws/containerinsights/${EKS_CLUSTER}/host
aws logs delete-log-group --log-group-name /aws/containerinsights/${EKS_CLUSTER}/performance

echo 'All done!'