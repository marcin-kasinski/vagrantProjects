#!/bin/bash
# set -o xtrace

source /vagrant/scripts/libs.sh
#exit 0

#DEV_BRANCH="stable/pike"
#DEV_BRANCH="stable/queens"
#DEV_BRANCH="stable/rocky"
DEV_BRANCH="stable/stein"
#DEV_BRANCH="master"

# Set global variables to control the names of the resources we create
KEYPAIR=mykey
VM1=myvm1
VM2=myvm2
IMAGE="xenial-server-cloudimg-amd64"
#IMAGE="cirros-0.3.5-x86_64-disk"

FLAVOR="m1.mkflavor"
NET1=mynetwork1
NET2=mynetwork2
NET1_CIDR="10.1.1.0/24"
NET2_CIDR="10.2.2.0/24"
SUBNET1=mysubnet1
SUBNET2=mysubnet2
ROUTER=myrouter
SG=mysecgroup
COMPUTE_NODENAME=node1
AZ=az2

#### External network & Floating IP Variables ####
PHYSNET=public
EXT_NET=public
# Set this to your External CIDR Range
EXT_NET_CIDR="192.168.1.0/24"
# The IP Address of your Internet Gateway
EXT_GATEWAY="192.168.1.1"
# Start and End IP address of the Allocation pool on the External Subnet
ALLOCATION_POOL_START="192.168.1.20"
ALLOCATION_POOL_END="192.168.1.99"
EXT_SUBNET="public-subnet"
# The floating IP address that you want Neutron to allocate from the pool
# Tip: Use the last IP address on the pool as your FIP to avoid conflicts with other IP's allocated by Neutron
FLOATING_IP="192.168.1.99"
########### End global variables ###########



#--------------------------------------------------------------------

#init

remove_LVM_logical_volume

setupNFS

#devstack/unstack.sh

#rm -rf /home/vagrant/devstack

clone_GIT

sudo cp /vagrant/ctr_local.conf devstack/local.conf 
			
#win2linux
sed -i -e 's/\r//g' devstack/local.conf
		
cp /vagrant/localrc.password devstack/.localrc.password 


#upgrade pip

echo "Upgrading PIP"

sudo apt-get install -y python-pip

/usr/bin/yes | sudo pip install --upgrade pip
/usr/bin/yes | sudo pip install -U os-testr 

cd devstack
git pull
cd ..
devstack/stack.sh

#bugfix in 3.15
#sudo pip install python-openstackclient==3.12

#restartFailedServices A1

#exit 0

#fix_OVS


#echo "exiting"
#exit 0

sudo touch /var/nfs/openstack_share/openstack_stack_finished

waitForNodeReady node1
#waitForNodeReady node2


source devstack/openrc admin admin


openstack flavor create --public m1.mkflavor --id auto --ram 8192 --disk 7 --vcpus 1 --rxtx-factor 1


addImage xenial-server-cloudimg-amd64 "http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img"

create_security_group SSHandICMP



sudo nova-manage cell_v2 discover_hosts --verbose 



updateCinder


#neutron router-gateway-clear  router1



source devstack/openrc admin admin
openstack router unset --external-gateway router1



#dla udemy
#configureExternalNetInterface eth2

#dla ubuntu
configureExternalNetInterface enp0s9

#chmod u+x /vagrant/scripts/automate-with-ext.sh

#/vagrant/scripts/automate-with-ext.sh

 echo "Creating virtual infrastructure..."


 create_keypair
 create_provider_external_network
 create_network $NET1
 create_network $NET2
 create_subnet $NET1 $SUBNET1 $NET1_CIDR
 create_subnet $NET2 $SUBNET2 $NET2_CIDR

create_external_subnet
create_router $ROUTER
add_router_interface $ROUTER $SUBNET1
add_router_interface $ROUTER $SUBNET2
set_router_gateway $ROUTER
create_security_group $SG

create_az 
allocate_floating_ip
boot_vm $VM1 $NET1 nova # Boot the first VM on NET1 and AZ named nova (default) (i.e. place VM1 on the controller)
#boot_vm $VM2 $NET2 $AZ  # Boot the second VM on NET2 and in AZ=az2 (i.e. place VM2 on the compute node)
create_volume "extra_space" 2  # Allocate some storage space

add_volume "extra_space"     # Attach the storage volume to $VM1

add_floating_ip $VM1   # Add a floating ip address to $VM1
create_volume "30gb-vol" 30  # Allocate some storage space
add_volume "30gb-vol"

#echo "setup magnum"

#setupMagnum

