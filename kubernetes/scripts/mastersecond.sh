#!/bin/bash
source /vagrant/scripts/libs.sh

sudo apt install -y default-jdk

echo I am provisioning...
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'

cd ~

setupJava 2>&1 | tee ~/setupJava.log

#configure_nfs 2>&1 | tee ~/configure_nfs.log


apt install -y nginx
echo "OK" > /var/www/html/master_second_init_completed

echo "curl k8smaster2/master_second_init_completed"

curl k8smaster2/master_second_init_completed

echo "Master second init end"

waitforurlOK http://k8smaster/certsforslavemasterscopied
copycertsonsecondmasternodes 2>&1 | tee ~/copycertsonsecondmasternodes.log
waitforurlOK http://k8smaster/join_command_sudo

joincommand="$retval --experimental-control-plane"
echo $joincommand
eval $joincommand

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

#setupkeepalived
#echo "forward port"
nohup kubectl port-forward -n kube-system  $(kubectl get po -n kube-system -l k8s-app=kubernetes-dashboard -o jsonpath="{.items[0].metadata.name}") 8443:8443  > /dev/null 2>&1 &

echo "DashboardToken ..."

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')

echo "Master second end"
