variable "NAME" {}
variable "PRIVATE_IP" {}
variable "SUBNET_ID" {}
variable "KEY_NAME" {}
variable "PATH_TO_PRIVATE_KEY" {}
#variable "BASTION_HOST" {}


#variable "DEPENDS_ON" {}


variable "AWS_REGION" {
  default = "us-east-1"
}
variable "AMI" {}

variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}


variable "VPC_SECURITY_GROUP_IDS" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
}

variable "VOLUME_TAGS" {
  type = "map"
  default = {
    "X" = "X"
    "Y" = "Y"
  }
}
