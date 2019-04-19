
log()
{
local message=$1

echo `date` "$message"
}

function installpackages()
{
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


#ls -l /usr/lib/cni/
#ls -l /opt/cni/bin


}


function initcluster()
{

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


}
function configurecluster()
{

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"



kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml


while ! kubectl get po -n kube-system -o wide | grep kubernetes-dashboard | grep Running ; do   echo "waiting for dashboard IP..." ; sleep 10 ; done

nohup kubectl port-forward -n kube-system  $(kubectl get po -n kube-system -l k8s-app=kubernetes-dashboard -o jsonpath="{.items[0].metadata.name}") 8443:8443  > /dev/null 2>&1 &
echo "DashboardToken ..."

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')

kubectl create clusterrolebinding kubernetes-dashboard-rolebinding --clusterrole=cluster-admin --serviceaccount kube-system:kubernetes-dashboard
##NIEBEZPIECZNE
kubectl create clusterrolebinding defaultdminrolebinding --clusterrole=cluster-admin --serviceaccount kube-system:default

#kubectl create namespace apps

#echo "" >a.yaml && nano a.yaml && kubectl apply -f a.yaml

export PATH=$PATH:/usr/local/bin
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

helm init


}

