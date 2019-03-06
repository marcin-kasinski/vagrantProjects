#!/bin/bash
source /vagrant/scripts/libs.sh



joinsecondaryMaster()
{

apt install -y nginx
echo "OK" > /var/www/html/master_second_init_completed

echo `date` "master_second_init_completed created"


echo "curl k8smaster2/master_second_init_completed"

curl k8smaster2/master_second_init_completed

echo "Master second init end"

waitforurlOK http://k8smaster/certsforslavemasterscopied

echo `date` "certsforslavemasterscopied finished"

copycertsonsecondmasternodes
echo `date` "certs copied from /temp"

waitforurlOK http://k8smaster/join_command_sudo

echo `date` "join_command_sudo finished"

joincommand="$retval --experimental-control-plane"
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
setupkeepalived

#echo "forward port"
nohup kubectl port-forward -n kube-system  $(kubectl get po -n kube-system -l k8s-app=kubernetes-dashboard -o jsonpath="{.items[0].metadata.name}") 8443:8443  > /dev/null 2>&1 &

echo "DashboardToken ..."

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')

}

#sudo apt install -y default-jdk

echo I am provisioning...
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'

cd ~


#configure_nfs 2>&1 | tee ~/configure_nfs.log

joinsecondaryMaster | tee ~/joinsecondaryMaster.log


echo "Master second end"
