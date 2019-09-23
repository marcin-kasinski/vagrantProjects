#!/bin/bash
packer build -machine-readable packer-example.json | tee build.log
AMI_ID=`egrep -oe 'ami-.{17}' build.log |tail -n1`

echo "AMI_ID=$AMI_ID"

echo 'variable "AMI_ID" { default = "'${AMI_ID}'" }' > /vagrant/terraform/demo/amivar.tf