start=$(date +%s)

echo $start > ~/start_time

sudo sh -c "echo 'export PATH=$PATH:/vagrant/scripts' >> /home/vagrant/.bashrc"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

sudo sh -c "echo '192.168.1.11 k8smaster.local' >> /etc/hosts"
sudo sh -c "echo '192.168.1.12 k8snode1.local' >> /etc/hosts"
sudo sh -c "echo '192.168.1.13 k8snode2.local' >> /etc/hosts"
sudo sh -c "echo '192.168.1.14 k8snode3.local' >> /etc/hosts"
sudo sh -c "echo '192.168.1.12 springbootmicroserviceingress' >> /etc/hosts"

sudo swapoff -a  
sudo sed -i -r '/swap/ s/^(.*)$/#\1/g' /etc/fstab
sudo sed -i -r '/cdrom/ s/^(.*)$/#\1/g' /etc/apt/sources.list
sudo apt -y update

sudo apt-get install -y ceph-common
sudo apt -y install -y docker.io
sudo apt install -y curl jq
sudo apt install -y apt-transport-https
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
#K8S_VERSION=1.12.0

#sudo apt install -qy kubelet=1.11.3-00 kubeadm=1.11.3-00  kubectl=1.11.3-00   kubernetes-cni 
#sudo apt install -y kubelet=${K8S_VERSION}-00 kubeadm=${K8S_VERSION}-00  kubectl=${K8S_VERSION}-00   kubernetes-cni 
sudo apt install -y kubelet kubeadm kubectl kubernetes-cni 
#sudo apt install -y kubelet kubeadm kubectl kubernetes-cni=0.6.0-00 

#list releases
#apt-cache policy kubernetes-cni
#return code
rc=$?

#kubectl get nodes

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

# nfs biblioteki klienckie
sudo apt-get install -y nfs-common

#get ceph conf from ceph server

#chmod 400 /root/.ssh/private_key_cephuser
scp -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key_cephuser cephuser@cephadmin:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key_cephuser cephuser@cephadmin:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring
scp -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key_cephuser cephuser@cephadmin:/home/cephuser/cluster/ceph.client.kube.keyring /etc/ceph/ceph.client.kube.keyring
