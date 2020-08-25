#!/bin/bash
source /vagrant/scripts/libs.sh

start=$(date +%s)

echo $start > /tmp/start_time

sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /home/vagrant/.bashrc"
sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /root/.bashrc"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

sudo sh -c "echo '192.168.1.11 k8smaster' >> /etc/hosts"
sudo sh -c "echo '192.168.1.12 k8smaster2' >> /etc/hosts"
sudo sh -c "echo '192.168.1.13 k8smaster3' >> /etc/hosts"
sudo sh -c "echo '192.168.1.14 k8snode1' >> /etc/hosts"
sudo sh -c "echo '192.168.1.15 k8snode2' >> /etc/hosts"
sudo sh -c "echo '192.168.1.16 k8snode2' >> /etc/hosts"
sudo sh -c "echo '192.168.1.21 cephadmin' >> /etc/hosts"
sudo sh -c "echo '192.168.1.22 cephosd1' >> /etc/hosts"
sudo sh -c "echo '192.168.1.23 cephosd2' >> /etc/hosts"
sudo sh -c "echo '192.168.1.24 cephosd3' >> /etc/hosts"
sudo sh -c "echo '192.168.1.25 cephmon1' >> /etc/hosts"

sudo sh -c "echo '192.168.1.12 springbootmicroserviceingress' >> /etc/hosts"

#set timezone
timedatectl set-timezone Europe/Warsaw

sudo yum install -y lvm2 nc net-tools tc

#configure_routing 2>&1 | tee ~/configure_routing.log

remove_LVM_logical_volume

sudo swapoff -a  
sudo sed -i -r '/swap/ s/^(.*)$/#\1/g' /etc/fstab
#sudo sed -i -r '/cdrom/ s/^(.*)$/#\1/g' /etc/apt/sources.list
#sudo apt -y update

#sudo apt-get install -y ceph-common

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

installnginx 2>&1 | tee ~/installnginx.log

installDocker 2>&1 | tee ~/installDocker.log

sudo yum install -y curl jq

sudo yum install -y mysql git

installKubernetes 2>&1 | tee ~/installKubernetes.log

configureFirewall 2>&1 | tee ~/configureFirewall.log

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

# nfs biblioteki klienckie
#sudo apt-get install -y nfs-common

#getConfFromCephServer

route
echo init.sh END