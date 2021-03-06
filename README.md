# Overview: terraform-bastion

Please note that this project makes some assumptions based on how I have my architecture designed. I choose to store remote state and variables inside S3. I use the Makefile to provide a clean interface to using Terraform and my Ansible projects. If you need help, please ask!

Builds the following infrastructure

* EC2 instance
* Route53 entries
* EIP because the bastion isn't in an ASG

- - - -
# Usage
The Makefile will pull down a fresh secrets variable file from S3 during the **plan** and **apply** phases. This file does not exist by default.

    export AWS_REGION="us-east-1"
    export AWS_STATE_BUCKET="my-state-bucket"
    export AWS_PROFILE="default"
    export AWS_KMS_ARN="arn:aws:kms:us-east-1:4545454545:key/xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
    export TF_VAR_kms_key_id=${AWS_KMS_ARN}
    export ENVIRONMENT="example"
    make plan
    make apply

- - - -
# Updating variables for an environment


    aws s3 --profile=default cp s3://my-state-bucket/terraform/bastion/example.tfvars .
    vim example.tfvars
    aws s3 --profile=default cp .tfvars s3://my-state-bucket/terraform/bastion/example.tfvars

- - - -
# Theme Music
[The Pine Hill Haints - I'm a Rambler, I'm a Gambler](https://www.youtube.com/watch?v=JMLJv7vptyA)

- - - -
# Author Information and License
GPLv3

(C) 2017 [Phil Porada](https://philporada.com) - philporada@gmail.com
