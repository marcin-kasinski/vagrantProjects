#!/bin/bash
# set -o xtrace

IP=$1


init(){

#			sudo sh -c "echo '192.168.1.11 hdp1' >> /etc/hosts"
#			sudo sh -c "echo '192.168.1.12 hdp2' >> /etc/hosts"
#			sudo sh -c "echo '192.168.1.13 hdp3' >> /etc/hosts"
#			sudo sh -c "echo '192.168.1.14 hdp4' >> /etc/hosts"
			
			echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
						
			sudo apt update
	
		sudo apt-get install mc -y 
		sudo apt-get install -y ntp ntpdate
		sudo sh -c "echo never >/sys/kernel/mm/transparent_hugepage/enabled"


}


setupNFS(){

 # ----------------------------- nfs -----------------------------

      
      	# nfs biblioteki klienckie
      	sudo apt-get install -y nfs-common

  		sudo mkdir -p /nfs/hdp_share
#      	sudo mount 192.168.33.10:/var/nfs/hdp_share /nfs/hdp_share
#  		sudo mount -t nfs -o vers=3,nolock,proto=tcp 192.168.33.10:/var/nfs/hdp_share /nfs/hdp_share 
  		sudo mount -t nfs -o nolock,proto=tcp hdp1.local:/var/nfs/hdp_share /nfs/hdp_share 
      # ----------------------------- nfs -----------------------------      

}


waitForStackFinished(){

		echo "waiting for stack finished..."
      
      	while [ ! -f /nfs/hdp_share/openstack_stack_finished ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for stack finished..." ;  sleep 30 ; done
      

}

waitForNFS(){

		echo "waiting for NFS server..."
      
		while ! nc -z hdp1.local 111; do   echo "waiting NFS to launch ..." ; sleep 30 ; done
		sleep 5      

}


waitForauthorized_keys(){

		echo "waiting for authorized_keys..."
      
      	while [ ! -f /nfs/hdp_share/master_authorized_keys ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for authorized_keys..." ;  sleep 30 ; done
      sudo cp /nfs/hdp_share/master_authorized_keys /root/.ssh/authorized_keys

}


init

waitForNFS
setupNFS

waitForauthorized_keys


hostname=$(hostname)

echo  "Creating /nfs/hdp_share/$hostname.ready"
sudo touch /nfs/hdp_share/$hostname.ready 

echo  "End..."
