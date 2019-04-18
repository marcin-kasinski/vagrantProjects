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

function init()
{
#zypper -n remove containerd
zypper -n install kubernetes-kubeadm
zypper -n install kubernetes-client
zypper -n install cni
zypper -n install cni-plugins

systemctl enable docker
systemctl start docker
systemctl enable kubelet.service
swapoff -a


ln -s /opt/cni/bin/weave-plugin-2.5.1 /usr/lib/cni/weave-ipam
ln -s /opt/cni/bin/weave-plugin-2.5.1 /usr/lib/cni/weave-net


ls -l /usr/lib/cni/
ls -l /opt/cni/bin

#rm -rf ~/.kube && kubeadm reset
IP="192.168.1.11"
echo $IP
kubeadm init --pod-network-cidr 10.32.0.0/12 --apiserver-advertise-address $IP --ignore-preflight-errors=all


#zypper packages --installed-only | grep kube



mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes



#taint pods on master nodes
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"



kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml



nohup kubectl port-forward -n kube-system  $(kubectl get po -n kube-system -l k8s-app=kubernetes-dashboard -o jsonpath="{.items[0].metadata.name}") 8443:8443  > /dev/null 2>&1 &
echo "DashboardToken ..."

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')

}