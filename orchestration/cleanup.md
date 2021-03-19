// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. // SPDX-License-Identifier: CC-BY-SA-4.0

# Introduction

This document describes the steps to remove the demonstration of Saga - Orchestration pattern.

> All instructions in this repository have been tested on Mac OS Catalina (10.15.7).

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
    - [Tools](#tools)
    - [Environment variables](#environment-variables)
  - [Clean up](#clean-up)

## Pre-requisites

An AWS account with full admininstrator access - _not_ the root account - should be used. Further, the following tools should be installed and the environment variables should be configured.

### Tools

The following CLI tools should be installed on the workstation.

1. CLI tools
   1. `git`
   2. `curl`
   3. `aws`
   4. `mysql`
   5. `docker`
   6. `kubectl`
   7. `eksctl`
   8. `helm`
   9. `jq`

**Notes**

1. `aws` CLI should be configured with the user with full administrator access.

### Environment variables

The following environment variables will be referenced regularly in various repositories. Configuring them before hand will simplify the overall procedure.

```bash
# Set the AWS region ID where this demo will be run e.g. ap-south-1
export REGION_ID=ap-south-1
# Set the AWS acouunt ID where this demo will be run e.g. 123456789012
export ACCOUNT_ID=123456789012
# Set the URL of the `git` repo where this code is hosted e.g. GitHub
export GIT_URL=https://github.com/aws-samples/<project>
```

Configure the AWS CLI with `aws configure` to use the same region ID as the value set for `REGION_ID` above.

## Clean up

To remove various projects of the Saga Orchestration pattern, follow the instructions of each repository as listed below _and in that order._

| Repository                                                                                 | Remarks                                   |
| ------------------------------------------------------------------------------------------ | ----------------------------------------- |
| [`eks-saga-cluster`](https://github.com/aws-samples/amazon-eks-saga-orchestration-cluster) | Amazon EKS cluster.                       |
| [`eks-saga-db`](https://github.com/aws-samples/amazon-eks-saga-orchestration-db)           | AWS RDS (MySQL) database.                 |
| [`eks-saga-aws`](https://github.com/aws-samples/amazon-eks-saga-orchestration-aws)         | AWS IAM, SQS, SNS and Amazon ECR objects. |
