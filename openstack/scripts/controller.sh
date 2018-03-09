#!/bin/bash
# set -o xtrace

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
      sudo apt-get install nfs-kernel-server
      
      # nfs biblioteki klienckie
      sudo apt-get install -y nfs-common
      
      # katalog dla joina:

      sudo mkdir /var/nfs/openstack_share -p
      sudo chown nobody:nogroup /var/nfs/openstack_share
      
      
      sudo sh -c "echo '/var/nfs/openstack_share    *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"      

      sudo exportfs -ra

      # ----------------------------- nfs -----------------------------      

}




# Creates a keypair
remove_LVM_logical_volume(){


#vagrant plugin creates logical volume.

#We have to remove it
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL
sudo lvmdiskscan
sudo lvscan
#umount /dev/MKmyvolgroup/vps
sudo lvremove -f /dev/MKmyvolgroup/vps
sudo lvscan
}


# Create a security group and add rules to permit ingress ICMP and SSH traffic
clone_GIT(){

			git clone --branch stable/pike https://git.openstack.org/openstack-dev/devstack
			sudo cp /vagrant/ctr_local.conf devstack/local.conf 
			
			#win2linux
			sed -i -e 's/\r//g' devstack/local.conf
			
			cp /vagrant/localrc.password devstack/.localrc.password 
			
			cd devstack
			./stack.sh



}

# Create a security group and add rules to permit ingress ICMP and SSH traffic
create_security_group(){

			local sgname=$1
			openstack security group create $sgname || { echo "failed to create security group $sgname" >&2; exit 1; }
			echo "Created security group $sgname"
			openstack security group rule create --ingress --dst-port 22 ${sgname} || { echo "error creating SSH rule for SG:$sgname" >&2; exit 1; }
			openstack security group rule create --ingress --protocol icmp ${sgname} || { echo "error creating ICMP rule for SG:$sgname" >&2; exit 1; }
			echo "Created SSH and ICMP rules for security group $sgname"

}

waitForNode1Ready(){

		echo "waiting for node1 ready..."
    
      
      	while [ ! -f /var/nfs/openstack_share/openstack_node1_ready ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for node1 ready..." ;  sleep 20 ; done
     

}


configureExternalNetInterface(){


openstack subnet list 

openstack subnet delete public-subnet

openstack subnet delete ipv6-public-subnet

openstack subnet list 

openstack network list

openstack network delete public

openstack network list

sudo ovs-vsctl list-br

sudo ovs-vsctl list-ports br-ex 


sudo ovs-vsctl add-port br-ex eth2 


sudo ovs-vsctl list-ports br-ex 

sudo ip link show eth2 

sudo ip link set dev eth2 up 

sudo ip link show eth2 


     

}



updateCinder(){

cp /etc/cinder/cinder.conf /etc/cinder/cinder_OLD.conf

cat /vagrant/cinder.conf >> /etc/cinder/cinder.conf
sudo sed -i -e 's/enabled_backends = lvmdriver-1/enabled_backends = lvmdriver-1,lvmdriver-2/g' /etc/cinder/cinder.conf 

#Restart Cinder Services.

sudo systemctl restart devstack@c-api.service
sudo systemctl restart devstack@c-vol.service
sudo systemctl restart devstack@c-sch.service




openstack volume type create --public LVM2
 
openstack volume type set LVM2 --property volume_backend_name=lvmdriver-2 


cinder get-pools

openstack volume create --size 40 40gb-vol_LVM2 --type LVM2


openstack volume list
}

#--------------------------------------------------------------------


#init
remove_LVM_logical_volume
#clone_GIT

setupNFS

devstack/unstack.sh
devstack/stack.sh

sudo touch /var/nfs/openstack_share/openstack_stack_finished

source devstack/openrc admin admin

create_security_group SSHandICMP

waitForNode1Ready

sudo nova-manage cell_v2 discover_hosts --verbose 


updateCinder





neutron router-gateway-clear  router1

configureExternalNetInterface

chmod u+x /vagrant/scripts/automate-with-ext.sh

/vagrant/scripts/automate-with-ext.sh


