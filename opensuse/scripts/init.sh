#!/bin/bash
source /vagrant/scripts/libs.sh

start=$(date +%s)

echo $start > /tmp/start_time

echo "INIT "
sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /home/vagrant/.bashrc"
sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /root/.bashrc"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

sudo sh -c "echo '192.168.1.11 k8smaster' >> /etc/hosts"
sudo sh -c "echo '192.168.1.12 k8smaster2' >> /etc/hosts"
sudo sh -c "echo '192.168.1.13 k8smaster3' >> /etc/hosts"

#zypper -n install docker


installpackages
