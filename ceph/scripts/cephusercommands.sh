#!/bin/bash

echo "cephuser command"
echo "I am $USER, with uid $UID"

#ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

echo "copy ssh config"
cp /vagrant/conf/sshconfig /home/cephuser/.ssh/config
echo "ssh config copied"
ls -l /home/cephuser/.ssh

chmod 644 /home/cephuser/.ssh/config


ssh-keyscan cephosd1 cephosd2 cephosd3 cephmon1 >> ~/.ssh/known_hosts

ssh-copy-id cephosd1
ssh-copy-id cephosd2
ssh-copy-id cephosd3
ssh-copy-id cephmon1


sudo pip install --upgrade pip
sudo pip install ceph-deploy

cd ~
mkdir cluster
cd cluster/
ceph-deploy new cephmon1

echo "public network = 192.168.1.0/24" >> cluster/ceph.conf
echo "osd pool default size = 2" >> cluster/ceph.conf

cat cluster/ceph.conf
#Now install Ceph on all nodes from the ceph-admin node with a single command.
ceph-deploy install cephadmin cephosd1 cephosd2 cephosd3 cephmon1

#Now deploy the monitor node on the cephmon1 node.
ceph-deploy mon create-initial
#The command will create a monitor key, check the key with this ceph command.
ceph-deploy gatherkeys cephmon1


#Check the available disk /dev/sdc on all osd nodes.
ceph-deploy disk list cephosd1 cephosd2 cephosd3

#Next, delete the partition tables on all nodes with the zap option.
ceph-deploy disk zap cephosd1 /dev/sdc
ceph-deploy disk zap cephosd2 /dev/sdc
ceph-deploy disk zap cephosd3 /dev/sdc


#Deploy a manager daemon. (Required only for luminous+ builds):
ceph-deploy mgr create cephmon1

#Now prepare all OSD nodes and ensure that there are no errors in the results.

ceph-deploy osd create --data /dev/sdc cephosd1
ceph-deploy osd create --data /dev/sdc cephosd2
ceph-deploy osd create --data /dev/sdc cephosd3

Now you can check the sdb disk on OSDS nodes again.

ceph-deploy disk list cephosd1 cephosd2 cephosd3

#Next, deploy the management-key to all associated nodes.
ceph-deploy admin cephadmin cephmon1 cephosd1 cephosd2 cephosd3



#Change the permission of the key file by running the command below on all nodes.


sudo chmod 644 /etc/ceph/ceph.client.admin.keyring
ssh cephuser@cephmon1 "sudo chmod 644 /etc/ceph/ceph.client.admin.keyring"
ssh cephuser@cephosd1 "sudo chmod 644 /etc/ceph/ceph.client.admin.keyring"
ssh cephuser@cephosd2 "sudo chmod 644 /etc/ceph/ceph.client.admin.keyring"
ssh cephuser@cephosd3 "sudo chmod 644 /etc/ceph/ceph.client.admin.keyring"

ceph health
ceph -s

