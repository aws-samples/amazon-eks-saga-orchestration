// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. // SPDX-License-Identifier: CC-BY-SA-4.0

# Introduction

This document describes the steps to install the demonstration of Saga - Orchestration pattern.

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Clean-up](#clean-up)

## Pre-requisites

An AWS account with full admininstrator access - _not_ the root account - should be used.

## Clean-up

1. Log on to the Cloud9 instance launched for installation.
2. Change `regionId` and `accountId` as applicable in the commands below. Do **NOT** change the third argument (`https://github.com/aws-samples`). Open terminal and run the commands.

```bash
cd
git clone https://github.com/aws-samples/amazon-eks-saga-orchestration
cd amazon-eks-saga-orchestration/scripts
./cleanup.sh regionId accountId https://github.com/aws-samples
```

3. Terminate your Cloud9 instance.

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
