#!/bin/bash
source /vagrant/scripts/libs.sh

#based on https://www.howtoforge.com/tutorial/how-to-install-a-ceph-cluster-on-ubuntu-16-04/

echo I am provisioning...
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#configure_nfs 2>&1 | tee ~/configure_nfs.log

start=$(cat ~/start_time)

#we need python packages for building the ceph-cluster. Install python and python-pip.
apt-get install -y python python-pip parted


waitForNodeReady cephosd1
waitForNodeReady cephosd2
waitForNodeReady cephosd3
waitForNodeReady cephmon1

sudo -H -u cephuser bash -c 'echo "I am $USER, with uid $UID"' 

cp /vagrant/scripts/cephusercommands.sh /home/cephuser/cephusercommands.sh
chown cephuser:cephuser -R /home/cephuser/
sudo -H -u cephuser bash -c '/home/cephuser/cephusercommands.sh' 

end=$(date +%s)

echo $end> ~/end_time

runtime_seconds=$((end-start))
runtime_minutes=$((runtime_seconds/ 60 ))

modulo=$((runtime_seconds % 60 ))

#echo Runtime $runtime_seconds seconds

echo Runtime $runtime_minutes minutes and $modulo seconds
