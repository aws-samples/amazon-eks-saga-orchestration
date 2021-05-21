// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. // SPDX-License-Identifier: CC-BY-SA-4.0

# Introduction

This document describes the steps to install the demonstration of Saga - Orchestration pattern.

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Installation](#installation)

## Pre-requisites

An AWS account with full admininstrator access - _not_ the root account - should be used.

## Installation

1. Launch a Cloud9 workspace as described [here](https://www.eksworkshop.com/020_prerequisites/workspace/). You may choose any name for the workshop.
2. Increase the disk size of the workspace as described [here](https://www.eksworkshop.com/020_prerequisites/workspace/#increase-the-disk-size-on-the-cloud9-instance).
3. Disable temporary credentials as described [here](https://www.eksworkshop.com/020_prerequisites/workspaceiam/).
4. Create new IAM role for your workspave as described [here](https://www.eksworkshop.com/020_prerequisites/iamrole/).
5. Attach new IAM role for your workspave as described [here](https://www.eksworkshop.com/020_prerequisites/ec2instance/).
6. Change `regionId` and `accountId` as applicable in the commands below. Do **NOT** change the third argument (`https://github.com/aws-samples`). Open terminal and run the commands.

```bash
cd
git clone https://github.com/aws-samples/amazon-eks-saga-orchestration
cd amazon-eks-saga-orchestration/scripts
./install.sh regionId accountId https://github.com/aws-samples
```

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

