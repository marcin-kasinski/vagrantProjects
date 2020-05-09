#!/bin/bash
source /vagrant/scripts/libs.sh

joinsecondaryMaster()
{

echo "OK" > /usr/share/nginx/html/master_second_init_completed
echo `date` "master_second_init_completed created"

#echo "Master second init end"
#waitforurlOK http://k8smaster/certsforslavemasterscopied
#echo `date` "certsforslavemasterscopied finished"
#copycertsonsecondmasternodes
#echo `date` "certs copied from /temp"

waitforurlOK http://k8smaster/join_command_for_control_pane

echo `date` "join_command_for_control_pane finished"

joincommand="$retval"


echo `date` "executing joincommand"
echo $joincommand

eval $joincommand

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# wait for init kubernetes HA executed
waitforurlOK http://k8smaster/master_init_completed

echo "OK" > /usr/share/nginx/html/master_second_joined_completed

waitforurlOK http://k8smaster/all_masters_completed
}

#sudo apt install -y default-jdk

echo I am provisioning...
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'

cd ~


#configure_nfs 2>&1 | tee ~/configure_nfs.log
configure_routing 2>&1 | tee ~/configure_routing.log

joinsecondaryMaster | tee ~/joinsecondaryMaster.log
setupkeepalived | tee ~/setupkeepalived.log


echo "Master second end"
