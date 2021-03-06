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

remove_LVM_logical_volume

sudo swapoff -a  
sudo sed -i -r '/swap/ s/^(.*)$/#\1/g' /etc/fstab
sudo sed -i -r '/cdrom/ s/^(.*)$/#\1/g' /etc/apt/sources.list
sudo apt -y update

sudo apt-get install -y ceph-common

installDocker 2>&1 | tee ~/installDocker.log

sudo apt install -y curl jq

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

UBUNTU_CODENAME=`cat /etc/os-release | grep UBUNTU_CODENAME | cut -d "=" -f 2`
echo "UBUNTU_CODENAME $UBUNTU_CODENAME"

sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main"> ~/kubernetes.list 
#sudo echo "deb http://apt.kubernetes.io/ kubernetes-$UBUNTU_CODENAME main"> ~/kubernetes.list 
sudo mv ~/kubernetes.list /etc/apt/sources.list.d/kubernetes.list
sudo apt update

sudo systemctl enable docker.service
sudo service docker start

# get kubernetes stable version
export K8S_VERSION=$(curl -sSL https://dl.k8s.io/release/stable.txt)

#remove 'v' character
K8S_VERSION=${K8S_VERSION//v}
echo $K8S_VERSION

#static
K8S_VERSION=1.12.3

#sudo apt install -y kubelet=${K8S_VERSION}-00 kubeadm=${K8S_VERSION}-00  kubectl=${K8S_VERSION}-00   kubernetes-cni 
sudo apt install -y kubelet kubeadm kubectl		

#list releases
#apt-cache policy kubernetes-cni
#return code
rc=$?

#kubectl get nodes

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

# nfs biblioteki klienckie
#sudo apt-get install -y nfs-common

#getConfFromCephServer