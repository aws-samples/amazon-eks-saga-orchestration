// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. // SPDX-License-Identifier: CC-BY-SA-4.0

# Introduction

This document describes the steps to install the demonstration of Saga - Orchestration pattern.

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Installation](#installation)

## Pre-requisites

An AWS account with full admininstrator access - _not_ the root account - should be used.

## Installation

1. Launch a Cloud9 workspace as described [here](https://docs.aws.amazon.com/cloud9/latest/user-guide/tutorial-create-environment.html). Use default values for all steps except for Step 8 where instance type is to be chosen as `t3.medium`.
2. In the terminal, run the following comands to increase space for the IDE instance. This will reboot the instance.

```bash
pip3 install --user --upgrade boto3
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
python -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print(resize)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"
if [ $? -eq 0 ]; then
    sudo reboot
fi
```

3. Disable AWS managed credentials as shown in the screen-shot below.
   1. Return to your Cloud9 workspace and click the gear icon (in top right corner)
   2. Select **AWS SETTINGS**
   3. Turn off **AWS managed temporary credentials**
   4. Close the Preferences tab 

![creds](../png/c9disableiam.png)

4. Create IAM role for workspace.
   1. Follow this [deep link](https://console.aws.amazon.com/iam/home#/roles$new?step=review&commonUseCase=EC2%2BEC2&selectedUseCase=EC2&policies=arn:aws:iam::aws:policy%2FAdministratorAccess&roleName=eks-saga-admin) to create an IAM role with **Administrator** access.
   2. Confirm that AWS service and EC2 are selected, then click **Next: Permissions** to view permissions.
   3. Confirm that AdministratorAccess is checked, then click **Next: Tags** to assign tags. Take the defaults, and click **Next: Review** to review.
   4. Enter `eks-saga-admi`n for the Name, and click Create role. 

5. Attach IAM role to the workspace.
   1. Click the grey circle button (in top right corner) and select **Manage EC2 Instance**.

![c9-role](../png/cloud9-role.png)
   
   2. Select the instance, then choose **Actions / Security / Modify IAM Role**

![c9-instanace-role](../png/c9instancerole.png)

   3. Choose `eks-saga-admin` from the IAM Role drop down, and select **Save**.

![c9-attach-iam](../png/attach-iam.png)

6. Change `regionId` and `accountId` as applicable in the commands below. Do **NOT** change the third argument (`https://github.com/aws-samples`). Open terminal and run the commands.

```bash
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

