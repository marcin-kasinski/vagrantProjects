#!/bin/bash
# set -o xtrace



setupNFS(){

 # ----------------------------- nfs -----------------------------
      sudo apt-get install -y nfs-kernel-server
      
      # nfs biblioteki klienckie
      sudo apt-get install -y nfs-common
      
      # katalog dla joina:

      sudo mkdir /var/nfs/hdp_share -p
      sudo chown nobody:nogroup /var/nfs/hdp_share
      
      
      sudo sh -c "echo '/var/nfs/hdp_share    *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"      

      sudo exportfs -ra
      
	  echo "set up NFS end."	      
      

      # ----------------------------- nfs -----------------------------      

}



waitForNodeReady(){

		local node_name=$1


		echo "waiting for $node_name ready..."
    
      
      	while [ ! -f /var/nfs/hdp_share/$node_name.ready ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for $node_name ready...(/var/nfs/hdp_share/$node_name.ready) " ;  sleep 20 ; done

}

init(){

#			sudo sh -c "echo '192.168.1.11 hdp1' >> /etc/hosts"
#			sudo sh -c "echo '192.168.1.12 hdp2' >> /etc/hosts"
#			sudo sh -c "echo '192.168.1.13 hdp3' >> /etc/hosts"
#			sudo sh -c "echo '192.168.1.14 hdp4' >> /etc/hosts"
			
			echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
						
			sudo apt update
	
		sudo apt-get install mc -y 
		apt-get install -y ntp ntpdate

		echo never >/sys/kernel/mm/transparent_hugepage/enabled

}



#--------------------------------------------------------------------


init

setupNFS


#sudo ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ""

sudo cp /vagrant/ssh/id_rsa.pub /root/.ssh/id_rsa.pub
sudo cp /vagrant/ssh/id_rsa /root/.ssh/id_rsa

sudo cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

sudo cp /root/.ssh/id_rsa.pub /var/nfs/hdp_share/master_authorized_keys

sudo wget -O /etc/apt/sources.list.d/ambari.list http://public-repo-1.hortonworks.com/ambari/ubuntu16/2.x/updates/2.6.1.5/ambari.list


sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD


sudo apt update
sudo apt install -y ambari-server

sudo ambari-server setup -s -v
sudo ambari-server start

waitForNodeReady hdp2
waitForNodeReady hdp3
waitForNodeReady hdp4


#sudo ssh-copy-id -i /root/.ssh/id_rsa.pub root@hdp1.local
#ssh-copy-id -i ~/.ssh/id_rsa.pub root@hdp2.local
#ssh-copy-id -i ~/.ssh/id_rsa.pub root@hdp3.local
#ssh-copy-id -i ~/.ssh/id_rsa.pub root@hdp4.local


