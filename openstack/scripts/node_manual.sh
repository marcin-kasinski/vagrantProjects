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


clone_GIT(){

			git clone --branch $DEV_BRANCH https://git.openstack.org/openstack-dev/devstack

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


#init

waitForNFS
setupNFS

#clone_GIT


#	sudo cp /vagrant/compute_local.conf devstack/local.conf 
			
		#win2linux
#		sed -i -e 's/\r//g' devstack/local.conf
#		cp /vagrant/localrc.password devstack/.localrc.password 

#devstack/unstack.sh
waitForStackFinished
#devstack/stack.sh




hostname=$(hostname)

echo  "Creating /nfs/openstack_share/$hostname.openstack_node_ready"
sudo touch /nfs/openstack_share/$hostname.openstack_node_ready 

sudo systemctl restart devstack@n-cpu.service
sudo systemctl status devstack@n-cpu.service