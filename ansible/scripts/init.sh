#!/bin/bash
#source /vagrant/scripts/libs.sh

start=$(date +%s)

echo $start > /tmp/start_time

sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /home/vagrant/.bashrc"
sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /root/.bashrc"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#sudo sh -c "echo '192.168.1.11 k8smaster' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.12 k8smaster2' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.13 k8smaster3' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.14 k8snode1' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.15 k8snode2' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.16 k8snode2' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.21 cephadmin' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.22 cephosd1' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.23 cephosd2' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.24 cephosd3' >> /etc/hosts"
#sudo sh -c "echo '192.168.1.25 cephmon1' >> /etc/hosts"

#sudo sh -c "echo '192.168.1.12 springbootmicroserviceingress' >> /etc/hosts"

#set timezone
timedatectl set-timezone Europe/Warsaw

sudo swapoff -a  
sudo sed -i -r '/swap/ s/^(.*)$/#\1/g' /etc/fstab
sudo sed -i -r '/cdrom/ s/^(.*)$/#\1/g' /etc/apt/sources.list
sudo apt -y update

sudo apt install -y curl jq
