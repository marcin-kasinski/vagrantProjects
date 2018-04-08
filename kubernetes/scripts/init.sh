echo I am provisioning...
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

      sudo swapoff -a  
      sudo sed -i -r '/swap/ s/^(.*)$/#\1/g' /etc/fstab
      sudo sed -i -r '/cdrom/ s/^(.*)$/#\1/g' /etc/apt/sources.list
      sudo apt -y update
      sudo apt -y install -y docker.io
      sudo apt install -y curl 
      sudo apt install -y apt-transport-https
      sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
      sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main"> ~/kubernetes.list 
      sudo mv ~/kubernetes.list /etc/apt/sources.list.d/kubernetes.list
      sudo apt update
      sudo apt install -y kubelet kubeadm kubectl  kubernetes-cni


      #kubectl get nodes
      
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1


      # nfs biblioteki klienckie
      sudo apt-get install -y nfs-common
