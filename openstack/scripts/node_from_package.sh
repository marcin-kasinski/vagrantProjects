#!/bin/bash
# set -o xtrace

IP=$1

#DEV_BRANCH="stable/pike"
DEV_BRANCH="stable/queens"
#DEV_BRANCH="master"


init(){

			#sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts
			
			#sudo sh -c "echo '192.168.33.10openstackmaster' >> /etc/hosts"
			
			
			echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
			
			sudo apt-get install sudo -y || yum install -y sudo
			
			sudo apt update
			sudo apt install -y python-systemd
			sudo apt-get install git -y || sudo yum install -y git
			sudo apt-get install mc -y 

}

setupNFS(){

 # ----------------------------- nfs -----------------------------

      
      	# nfs biblioteki klienckie
      	sudo apt-get install -y nfs-common

  		sudo mkdir -p /nfs/openstack_share
#      	sudo mount 192.168.33.10:/var/nfs/openstack_share /nfs/openstack_share
#  		sudo mount -t nfs -o vers=3,nolock,proto=tcp 192.168.33.10:/var/nfs/openstack_share /nfs/openstack_share 
  		sudo mount -t nfs -o nolock,proto=tcp 192.168.33.10:/var/nfs/openstack_share /nfs/openstack_share 
      # ----------------------------- nfs -----------------------------      

}


waitForStackFinished(){

		echo "waiting for stack finished..."
      
      	while [ ! -f /nfs/openstack_share/openstack_stack_finished ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for stack finished..." ;  sleep 30 ; done
      

}

waitForNFS(){

		echo "waiting for NFS server..."
      
		while ! nc -z 192.168.33.10 111; do   echo "waiting NFS to launch ..." ; sleep 30 ; done
		sleep 5      

}


init

waitForNFS
setupNFS

#waitForStackFinished


sudo apt install -y software-properties-common
sudo add-apt-repository -y cloud-archive:queens

sudo apt update && sudo apt dist-upgrade
#sudo apt install -y python-openstackclient

sudo apt-get install -y qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils

sudo apt-get install -y qemu-kvm qemu virt-manager virt-viewer libvirt-bin

sudo apt-get install -y libguestfs-tools

sudo apt install -y nova-compute


#nano /etc/nova/nova.conf





sudo systemctl restart nova-compute.service
#sudo journalctl -f --unit nova-compute.service




hostname=$(hostname)

echo  "Creating /nfs/openstack_share/$hostname.openstack_node_ready"
sudo touch /nfs/openstack_share/$hostname.openstack_node_ready 


