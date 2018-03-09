#!/bin/bash
# set -o xtrace

setupNFS(){

 # ----------------------------- nfs -----------------------------

      
      	# nfs biblioteki klienckie
      	sudo apt-get install -y nfs-common

  		sudo mkdir -p /nfs/openstack_share
      	sudo mount 192.168.33.10:/var/nfs/openstack_share /nfs/openstack_share
  
      # ----------------------------- nfs -----------------------------      

}


waitForStackFinished(){

		echo "waiting for stack finished..."
      
      	while [ ! -f /nfs/openstack_share/openstack_stack_finished ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for stack finished..." ;  sleep 20 ; done
      

}

waitForNFS(){

		echo "waiting for NFS server..."
      
		while ! nc -z 192.168.33.10 111; do   echo "waiting NFS to launch ..." ; sleep 5 ; done
      

}

waitForNFS
setupNFS
waitForStackFinished

sudo touch /nfs/openstack_share/openstack_node1_ready

sudo systemctl restart devstack@n-cpu.service
sudo systemctl status devstack@n-cpu.service