#!/bin/bash

sudo yum install -y net-tools
sudo yum install -y unzip



installTerraform()
{

#install terraform
#for graph 
sudo yum install -y graphviz
#wget -q https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip
curl -q https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip -o terraform_0.12.8_linux_amd64.zip
unzip terraform_0.12.8_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform*

}


installPacker()
{

#install packer
#wget -q https://releases.hashicorp.com/packer/1.4.3/packer_1.4.3_linux_amd64.zip
curl https://releases.hashicorp.com/packer/1.4.3/packer_1.4.3_linux_amd64.zip -o packer_1.4.3_linux_amd64.zip

unzip packer_1.4.3_linux_amd64.zip
sudo mv packer /usr/local/bin/
rm packer*
}


installAnsible()
{

sudo yum install -y epel-release
sudo yum install -y ansible
}


