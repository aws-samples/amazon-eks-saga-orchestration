#!/bin/bash
set -e
cd $HOME

## Base tools
sudo yum update -y && sudo yum install -y mysql

### jq - yum install jq1.5 whereas, the walk command requires jq1.6
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
chmod +x jq
sudo mv jq /usr/local/bin

### kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin
kubectl version --client=true

### eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

### helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | /bin/bash -
helm version

## Remove cluster objects, EKS cluster and ELB
export RDS_DB_ID=eks-sagao-db
export EKS_CLUSTER=eks-saga-orchestration
export EKS_VPC=`aws eks describe-cluster --name ${EKS_CLUSTER} --query 'cluster.resourcesVpcConfig.vpcId' --output text`
export RDS_VPC=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DBSubnetGroup.VpcId' --output text`

# aws eks update-kubeconfig --name ${EKS_CLUSTER}

STACK_NAME=eksctl-${EKS_CLUSTER}-cluster
if [ ! -d "$HOME/amazon-eks-saga-orchestration-cluster" ]; then
  git clone ${GIT_URL}/amazon-eks-saga-orchestration-cluster
fi
git clone ${GIT_URL}/amazon-eks-saga-orchestration-cluster
cd amazon-eks-saga-orchestration-cluster/scripts
./cleanup.sh ${STACK_NAME} ${ACCOUNT_ID} ${RDS_DB_ID} ${EKS_VPC} ${RDS_VPC} ${EKS_CLUSTER}
cd

## Remove RDS
if [ ! -d "$HOME/amazon-eks-saga-orchestration-db" ]; then
  git clone ${GIT_URL}/amazon-eks-saga-orchestration-db
fi
export PROJECT_HOME=${PWD}/amazon-eks-saga-orchestration-db
# Use changed password !!
export MYSQL_MASTER_PASSWORD='V3ry.Secure.Passw0rd'
source ${PROJECT_HOME}/scripts/drop.sh
source ${PROJECT_HOME}/scripts/cleanup.sh ${ACCOUNT_ID} ${RDS_DB_ID}
cd

## Remove SNS, SQS, IAM and ECR
if [ ! -d "$HOME/amazon-eks-saga-orchestration-aws" ]; then
  git clone ${GIT_URL}/amazon-eks-saga-orchestration-aws
fi
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