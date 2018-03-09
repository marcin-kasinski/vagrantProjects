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



# Creates a keypair
remove_LVM_logical_volume(){

			#vagrant plugin creates logical volume.
			#We have to remove it
			sudo lvscan
			#umount /dev/MKmyvolgroup/vps
			lvremove /dev/MKmyvolgroup/vps
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

#--------------------------------------------------------------------


#init
remove_LVM_logical_volume
#clone_GIT

source openrc admin admin


create_security_group SSHandICMP
