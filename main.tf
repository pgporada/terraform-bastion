variable "region" {}
variable "env" {}
variable "aws_account_id" {}
variable "key_path" {}
variable "key_name" {}
variable "ec2_bastion_instance_type" {}
variable "ec2_bastion_user" {}
variable "access" {}
variable "secret" {}
variable "ip_allow1" {}
variable "ip_allow2" {}
variable "ip_allow3" {}
variable "ip_allow4" {}

terraform {
  required_version = ">= 0.9.4"
  backend "s3" {
    encrypt    = 1
    acl        = "private"
    bucket     = "pgporada-state"
  }
}

provider "aws" {
  region              = "${var.region}"
  profile             = "${var.env}"
  allowed_account_ids = ["544271576467"]
  access_key          = "${var.access}"
  secret_key          = "${var.secret}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region     = "${var.region}"
    bucket     = "bucket"
    key        = "terraform/vpc/${var.env}.tfstate"
    profile    = "${var.env}"
    encrypt    = 1
    acl        = "private"
    kms_key_id = "${var.kms_key_id}"
  }
}

module "bastion" {
  source           = "modules/bastion"
  env              = "${var.env}"
  region           = "${var.region}"
  instance_type    = "${var.ec2_bastion_instance_type}"
  bastion_key_name = "${var.key_name}"
  bastion_key_path = "${var.key_path}"
  vpc_id           = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_cidr         = "${data.terraform_remote_state.vpc.vpc_cidr}"
  subnet_ids       = "${data.terraform_remote_state.vpc.public_subnet_ids}"
  shell_username   = "${var.ec2_bastion_user}"
  ip_allow1        = "${var.ip_allow1}"
  ip_allow2        = "${var.ip_allow2}"
  ip_allow3        = "${var.ip_allow3}"
  ip_allow4        = "${var.ip_allow4}"
}

output "environment" {
  value = "${var.env}"
}

output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}

output "bastion_private_ip" {
  value = "${module.bastion.private_ip}"
}

output "bastion_user" {
  value = "${var.ec2_bastion_user}"
}

output "bastion_ami_image_id" {
  value = "${module.bastion.ami_image_id}"
}

output "bastion_ami_creation_date" {
  value = "${module.bastion.ami_creation_date}"
}

output "bastion_ami_name" {
  value = "${module.bastion.ami_name}"
}
