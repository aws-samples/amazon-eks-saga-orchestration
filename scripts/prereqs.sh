#!/bin/bash
set -ex

## Base installation

### Tools - git and mysql client
sudo yum-config-manager --setopt="docker-ce-stable.baseurl=https://download.docker.com/linux/centos/7/x86_64/stable" --save
sudo yum update -y && sudo yum install -y mysql docker && sudo systemctl start docker

### Set docker to run without root
sudo usermod -aG docker $USER

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

### jq - yum install jq1.5 whereas, the walk command requires jq1.6
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
chmod +x jq
sudo mv jq /usr/local/bin
