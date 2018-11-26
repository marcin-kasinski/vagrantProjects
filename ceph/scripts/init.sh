#!/bin/bash

start=$(date +%s)

echo $start > ~/start_time

sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /home/vagrant/.bashrc"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

sudo swapoff -a  
sudo sed -i -r '/swap/ s/^(.*)$/#\1/g' /etc/fstab
sudo sed -i -r '/cdrom/ s/^(.*)$/#\1/g' /etc/apt/sources.list
sudo apt -y update
sudo apt install -y curl jq
sudo apt install -y curl python
sudo apt install -y apt-transport-https

#ntp
sudo apt-get install -y ntp ntpdate ntp-doc
ntpdate 0.us.pool.ntp.org
hwclock --systohc
systemctl enable ntp
systemctl start ntp

# nfs biblioteki klienckie
#sudo apt-get install -y nfs-common

#allow login using user
#sed -i -e "\\#PasswordAuthentication no# s#PasswordAuthentication no#PasswordAuthentication yes#g" /etc/ssh/sshd_config
#systemctl restart sshd.service



# add cephuser 
useradd -m -s /bin/bash cephuser
echo 'cephuser:secret' | chpasswd

echo "cephuser ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/cephuser
chmod 0440 /etc/sudoers.d/cephuser
sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers

mkdir /home/cephuser/.ssh/


cp /tmp/ssh_pub_key /home/cephuser/.ssh/id_rsa.pub
cp /tmp/ssh_pub_key /home/cephuser/.ssh/authorized_keys
cp /tmp/ssh_private_key /home/cephuser/.ssh/id_rsa
chmod 400 /home/cephuser/.ssh/id_rsa

chown cephuser:cephuser -R /home/cephuser/.ssh/

