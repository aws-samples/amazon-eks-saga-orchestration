// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. // SPDX-License-Identifier: CC-BY-SA-4.0

# Introduction

This document describes the steps to install the demonstration of Saga - Orchestration pattern.

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Installation](#installation)
    - [Automated installation](#automated-installation)

## Pre-requisites

An AWS account with full admininstrator access - _not_ the root account - should be used.

## Installation

### Automated installation

1. Launch a EC2 instance with the Amazon Linux 2 AMI with the following guidelines.
   1. Instance type could be as small as `t2.micro`.
   2. **Strongly recommend** to use Spot instance to reduce costs.
   3. Launch in the same region where the cluster is to be launched.
   4. Launch the instance with public IP address with port `22` opened for `ssh` access.
2. Once the instance is launched, connect to it with `ssh` and run the following commands.

```bash
git clone https://github.com/aws-samples/amazon-eks-saga-orchestration
cd amazon-eks-saga-orchestration/scripts
./prereqs.sh
logout
```

3. Your connection will be lost after running the above commands. This is required so that your user (`ec2-user`) is added to the `docker` group for running various `docker` commands. Therefore, connect back with `ssh` and follow the steps below.
4. Configure `aws` CLI with `aws configure` for an IAM user that has administrator access.
5. Define the following environment variables.

```bash
export REGION_ID=<preferred region ID>
export ACCOUNT_ID=<your account ID>
# Do not change this.
export GIT_URL=https://github.com/aws-samples
```

6. In `amazon-eks-saga-orchestration/scripts/install.sh`, edit the value of `MYSQL_MASTER_PASSWORD`.
7. Run the following commands to launch the installation.

```bash
cd amazon-eks-saga-orchestration/scripts
./install.sh
```

7. Terminate this EC2 instance.

You can also browse the instructions for each repository as listed below.

| Repository                                                                                           | Remarks                                   |
| ---------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| [`eks-saga-aws`](https://github.com/aws-samples/amazon-eks-saga-orchestration-aws)                   | AWS IAM, SQS, SNS and Amazon ECR objects. |
| [`eks-saga-db`](https://github.com/aws-samples/amazon-eks-saga-orchestration-db)                     | AWS RDS (MySQL) database.                 |
| [`eks-saga-cluster`](https://github.com/aws-samples/amazon-eks-saga-orchestration-cluster)           | Amazon EKS cluster.                       |
| [`eks-saga-orders`](https://github.com/aws-samples/amazon-eks-saga-orchestration-orders)             | Orders microservice.                      |
| [`eks-saga-ordersrb`](https://github.com/aws-samples/amazon-eks-saga-orchestration-orders-rb)        | Orders rollback microservice.             |
| [`eks-saga-inventory`](https://github.com/aws-samples/amazon-eks-saga-orchestration-inventory)       | Inventory microservice.                   |
| [`eks-saga-audit`](https://github.com/aws-samples/amazon-eks-saga-orchestration-audit)               | Audit microservice.                       |
| [`eks-saga-trail`](https://github.com/aws-samples/amazon-eks-saga-orchestration-trail)               | Trail microservice.                       |
| [`eks-saga-orchestrator`](https://github.com/aws-samples/amazon-eks-saga-orchestration-orchestrator) | Orchestrator microservice.                |
