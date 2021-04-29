#!/bin/bash
set -ex
cd $HOME

## AWS set-up

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

### RDS
git clone ${GIT_URL}/amazon-eks-saga-orchestration-db
PROJECT_HOME=${PWD}/amazon-eks-saga-orchestration-db
# Change this password !!
MYSQL_MASTER_PASSWORD='V3ry.Secure.Passw0rd'
RDS_DB_ID=eks-sagao-db
source ${PROJECT_HOME}/scripts/db.sh
source ${PROJECT_HOME}/scripts/ddl.sh

### RDS IAM
cd ${PROJECT_HOME}/scripts
export DB_RESOURCE_ID=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DbiResourceId' --output text`
./iam.sh ${REGION_ID} ${ACCOUNT_ID} ${DB_RESOURCE_ID}
DB_ENDPOINT=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].Endpoint.Address' --output text`
cd

## Amazon EKS cluster set-up

export EKS_CLUSTER=eks-saga-orchestration

### Cluster installation
git clone ${GIT_URL}/amazon-eks-saga-orchestration-cluster
cd amazon-eks-saga-orchestration-cluster/yaml
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/eks-saga-demoType/'"${EKS_CLUSTER}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/sns-policy/eks-saga-sns-orche-policy/g' \
  -e 's/sqs-policy/eks-saga-sqs-orche-policy/g' \
  cluster.yaml | eksctl create cluster -f -

### Set log group retention
aws logs put-retention-policy --log-group-name /aws/eks/${EKS_CLUSTER}/cluster --retention-in-days 1

### EKS RDS access
export EKS_VPC=`aws eks describe-cluster --name ${EKS_CLUSTER} --query 'cluster.resourcesVpcConfig.vpcId' --output text`
export RDS_VPC=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DBSubnetGroup.VpcId' --output text`
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
git clone ${GIT_URL}/amazon-eks-saga-orchestration-orders
cd amazon-eks-saga-orchestration-orders/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  orders.yaml | kubectl -n eks-saga create -f -
cd

### Inventory microservice
git clone ${GIT_URL}/amazon-eks-saga-orchestration-inventory
cd amazon-eks-saga-orchestration-inventory/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  inventory.yaml | kubectl -n eks-saga create -f -
cd

### Orchestrator microservice
git clone ${GIT_URL}/amazon-eks-saga-orchestration-orchestrator
cd amazon-eks-saga-orchestration-orchestrator/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  orchestrator.yaml | kubectl -n eks-saga create -f -
cd

### Audit microservice
git clone ${GIT_URL}/amazon-eks-saga-orchestration-audit
cd amazon-eks-saga-orchestration-audit/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  audit.yaml | kubectl -n eks-saga create -f -
cd

### Trail microservice
git clone ${GIT_URL}/amazon-eks-saga-orchestration-trail
cd amazon-eks-saga-orchestration-trail/yaml
sed -e 's#timeZone#Asia/Kolkata#g' \
  -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/dbEndpoint/'"${DB_ENDPOINT}"'/g' \
  cfgmap.yaml | kubectl -n eks-saga create -f -
sed -e 's/regionId/'"${REGION_ID}"'/g' \
  -e 's/accountId/'"${ACCOUNT_ID}"'/g' \
  trail.yaml | kubectl -n eks-saga create -f -
cd

## Set retention period for log groups of Container Insights
sleep 30

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
