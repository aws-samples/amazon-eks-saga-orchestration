#!/bin/bash
set -e

if [[ $# -ne 3 ]] ; then
  echo 'USAGE: ./install.sh regionId accountId gitUrl'
  exit 1
fi

REGION_ID=$1
ACCOUNT_ID=$2
GIT_URL=$3

## Base installation

### Tools - mysql client
sudo yum update -y && sudo yum install -y mysql

### kubectl
echo 'Installing kubectl'
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin
kubectl version --client=true

### eksctl
echo 'Installing eksctl'
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

### helm
echo 'Installing helm'
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | /bin/bash -
helm version

### jq - yum install jq1.5 whereas, the walk command requires jq1.6
echo 'Installing jq'
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
chmod +x jq
sudo mv jq /usr/local/bin

### yq
VERSION=v4.9.1
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && chmod +x /usr/bin/yq

### AWS CLI
echo 'Uninstalling AWS CLI 1 and installing AWS CLI 2'
sudo pip uninstall -y awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo mv /usr/local/bin/aws /usr/bin/aws

### Configure AWS CLI for region
aws configure set default.region ${REGION_ID}

## Saga Orchestration installation
echo 'Installing EKS Saga Orchestration demo.'
cd $HOME

## AWS set-up
echo 'Setting up SNS, SQS, IAM and ECR objects'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-aws
cd amazon-eks-saga-orchestration-aws/scripts

### SQS and SNS set-up
./orchestration.sh ${REGION_ID} ${ACCOUNT_ID}

### IAM set-up
./iam.sh ${REGION_ID} ${ACCOUNT_ID} O

### ECR set-up
./ecr.sh C

### Build and push images
./images.sh ${REGION_ID} ${ACCOUNT_ID} ${GIT_URL} O
cd

## AWS RDS set-up
echo 'Setting up RDS instance'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-db

### RDS
PROJECT_HOME=${PWD}/amazon-eks-saga-orchestration-db
# Change this password !!
MYSQL_MASTER_PASSWORD='V3ry.Secure.Passw0rd'
RDS_DB_ID=eks-sagao-db
source ${PROJECT_HOME}/scripts/db.sh
source ${PROJECT_HOME}/scripts/ddl.sh

### RDS IAM
cd ${PROJECT_HOME}/scripts
DB_RESOURCE_ID=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DbiResourceId' --output text`
./iam.sh ${REGION_ID} ${ACCOUNT_ID} ${DB_RESOURCE_ID}
DB_ENDPOINT=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].Endpoint.Address' --output text`
cd

## Amazon EKS cluster set-up
echo 'Setting up EKS cluster'
EKS_CLUSTER=eks-saga-orchestration

### Cluster installation
git clone ${GIT_URL}/amazon-eks-saga-orchestration-cluster
cd amazon-eks-saga-orchestration-cluster/yaml
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/eks-saga-demoType/'"${EKS_CLUSTER}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/elb-policy/eks-saga-elb-orche-policy/g' \
  -e 's/sns-policy/eks-saga-sns-orche-policy/g' \
  -e 's/sqs-policy/eks-saga-sqs-orche-policy/g' \
  -e 's/rds-policy/eks-saga-rds-orche-policy/g' \
  cluster.yaml | eksctl create cluster -f -

### Set log group retention
aws logs put-retention-policy --log-group-name /aws/eks/${EKS_CLUSTER}/cluster --retention-in-days 1

### EKS RDS access
EKS_VPC=`aws eks describe-cluster --name ${EKS_CLUSTER} --query 'cluster.resourcesVpcConfig.vpcId' --output text`
RDS_VPC=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DBSubnetGroup.VpcId' --output text`
cd ../scripts
STACK_NAME=eksctl-${EKS_CLUSTER}-cluster
./rds.sh ${STACK_NAME} ${EKS_VPC} ${RDS_VPC} ${RDS_DB_ID}

### Load balancer set-up
./elb.sh ${ACCOUNT_ID}

### Container Insights
ClusterName=${EKS_CLUSTER}
LogRegion=${REGION_ID}
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${LogRegion}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f - 
cd

## Deploy microservices

### Orders microservice
echo 'Deploying Orders microservice'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-orders
cd amazon-eks-saga-orchestration-orders/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -

yq e 'select(di == 0)' orders.yaml | sed -e 's/regionId/'"${REGION_ID}"'/g' -e 's/accountId/'"${ACCOUNT_ID}"'/g' - | kubectl -n eks-saga create -f -
yq e 'select(di == 1)' orders.yaml | kubectl -n eks-saga create -f -
cd

### Inventory microservice
echo 'Deploying Inventory microservice'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-inventory
cd amazon-eks-saga-orchestration-inventory/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -

yq e 'select(di == 0)' inventory.yaml | sed -e 's/regionId/'"${REGION_ID}"'/g' -e 's/accountId/'"${ACCOUNT_ID}"'/g' - | kubectl -n eks-saga create -f -
yq e 'select(di == 1)' inventory.yaml | kubectl -n eks-saga create -f -
cd

### Orchestrator microservice
echo 'Deploying Orchestrator microservice'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-orchestrator
cd amazon-eks-saga-orchestration-orchestrator/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -

yq e 'select(di == 0)' orchestrator.yaml | sed -e 's/regionId/'"${REGION_ID}"'/g' -e 's/accountId/'"${ACCOUNT_ID}"'/g' - | kubectl -n eks-saga create -f -
yq e 'select(di == 1)' orchestrator.yaml | kubectl -n eks-saga create -f -
cd

### Audit microservice
echo 'Deploying Audit microservice'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-audit
cd amazon-eks-saga-orchestration-audit/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -

yq e 'select(di == 0)' audit.yaml | sed -e 's/regionId/'"${REGION_ID}"'/g' -e 's/accountId/'"${ACCOUNT_ID}"'/g' - | kubectl -n eks-saga create -f -
yq e 'select(di == 1)' audit.yaml | kubectl -n eks-saga create -f -
cd

### Trail microservice
echo 'Deploying Trail microservice'
git clone ${GIT_URL}/amazon-eks-saga-orchestration-trail
cd amazon-eks-saga-orchestration-trail/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -

yq e 'select(di == 0)' trail.yaml | sed -e 's/regionId/'"${REGION_ID}"'/g' -e 's/accountId/'"${ACCOUNT_ID}"'/g' - | kubectl -n eks-saga create -f -
yq e 'select(di == 1)' trail.yaml | kubectl -n eks-saga create -f -
cd

### Sleeping 30s so that Ingress object could be created.
### See https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/2013
echo 'Sleeping 30s so that Ingress objects could be created next.'
sleep 30

echo 'Creating Ingress for Orders microservice'
cd amazon-eks-saga-orchestration-orders/yaml
yq e 'select(di == 2)' orders.yaml | kubectl -n eks-saga create -f -
cd

echo 'Creating Ingress for Inventory microservice'
cd amazon-eks-saga-orchestration-inventory/yaml
yq e 'select(di == 2)' inventory.yaml | kubectl -n eks-saga create -f -
cd

echo 'Creating Ingress for Orchestrator microservice'
cd amazon-eks-saga-orchestration-orchestrator/yaml
yq e 'select(di == 2)' orchestrator.yaml | kubectl -n eks-saga create -f -
cd

echo 'Creating Ingress for Audit microservice'
cd amazon-eks-saga-orchestration-audit/yaml
yq e 'select(di == 2)' audit.yaml | kubectl -n eks-saga create -f -
cd

echo 'Creating Ingress for Trail microservice'
cd amazon-eks-saga-orchestration-trail/yaml
yq e 'select(di == 2)' trail.yaml | kubectl -n eks-saga create -f -
cd

echo 'Setting retention periods for CloudWatch log groups'
LOG_GROUP_NAME=/aws/containerinsights/${EKS_CLUSTER}/application
LOG_GROUP_ARN=`aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP_NAME} --query 'logGroups[0].arn' --output text`
if [ ${LOG_GROUP_ARN} == 'None' ]
then
  echo "${LOG_GROUP_NAME} should be available after some time. Please set retention period manually to 1 day to avoid incurring charges."
else
  aws logs put-retention-policy --log-group-name ${LOG_GROUP_NAME} --retention-in-days 1
  echo "Retention period for ${LOG_GROUP_NAME} set to 1 day."
fi 

LOG_GROUP_NAME=/aws/containerinsights/${EKS_CLUSTER}/dataplane
LOG_GROUP_ARN=`aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP_NAME} --query 'logGroups[0].arn' --output text`
if [ ${LOG_GROUP_ARN} == 'None' ]
then
  echo "${LOG_GROUP_NAME} should be available after some time. Please set retention period manually to 1 day to avoid incurring charges."
else
  aws logs put-retention-policy --log-group-name ${LOG_GROUP_NAME} --retention-in-days 1
  echo "Retention period for ${LOG_GROUP_NAME} set to 1 day."
fi 

LOG_GROUP_NAME=/aws/containerinsights/${EKS_CLUSTER}/host
LOG_GROUP_ARN=`aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP_NAME} --query 'logGroups[0].arn' --output text`
if [ ${LOG_GROUP_ARN} == 'None' ]
then
  echo "${LOG_GROUP_NAME} should be available after some time. Please set retention period manually to 1 day to avoid incurring charges."
else
  aws logs put-retention-policy --log-group-name ${LOG_GROUP_NAME} --retention-in-days 1
  echo "Retention period for ${LOG_GROUP_NAME} set to 1 day."
fi

LOG_GROUP_NAME=/aws/containerinsights/${EKS_CLUSTER}/performance
LOG_GROUP_ARN=`aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP_NAME} --query 'logGroups[0].arn' --output text`
if [ ${LOG_GROUP_ARN} == 'None' ]
then
  echo "${LOG_GROUP_NAME} should be available after some time. Please set retention period manually to 1 day to avoid incurring charges."
else
  aws logs put-retention-policy --log-group-name ${LOG_GROUP_NAME} --retention-in-days 1
  echo "Retention period for ${LOG_GROUP_NAME} set to 1 day."
fi 

echo 'Cleaning up folders'
rm -rf $HOME/amazon-eks-saga-orchestration-audit
rm -rf $HOME/amazon-eks-saga-orchestration-aws
rm -rf $HOME/amazon-eks-saga-orchestration-cluster
rm -rf $HOME/amazon-eks-saga-orchestration-db
rm -rf $HOME/amazon-eks-saga-orchestration-inventory
rm -rf $HOME/amazon-eks-saga-orchestration-orchestrator
rm -rf $HOME/amazon-eks-saga-orchestration-orders
rm -rf $HOME/amazon-eks-saga-orchestration-trail

echo 'All done!'