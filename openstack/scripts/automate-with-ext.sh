#!/bin/bash
# set -o xtrace

#########################################################################################
# Author: Naveen Joy
# Udemy Course Name: Fundamentals of the OpenStack Cloud with Hands-on Labs
# Course URL: https://www.udemy.com/deep-dive-the-openstack-cloud/?couponCode=NJ_STUDENT
#########################################################################################
#
# This script creates the following cloud resources using the OpenStack CLI Client:
#   A KeyPair
#   Two project networks (VXLAN) and their corresponding subnets
#   A router with interfaces added to both networks
#   A security-group with rules to allow ingress ssh and ICMP ping traffic
#   A host aggregate and exposes it as an Availability Zone named az2
#   Adds the compute host named "node1" to az2
#   Launches a VM ($VM1) on the default AZ (nova)
#   Launches another VM ($VM2) on az2
#   Creates a Volume
#   Attaches the Volume to $VM1
#
#  When the variable CLEANUP is set, it cleans up existing resources.
#  Use the variable CREATE to control the creation of resources
#########################################################################################

#########################################################################################
# Source Admin credentials
source /home/vagrant/devstack/openrc admin admin

# Variables that control the script action
CLEANUP=1  # When set, do a cleanup run to delete all old resources
CREATE=1   # When set, create cloud resources

# Set global variables to control the names of the resources we create
KEYPAIR=mykey
VM1=myvm1
VM2=myvm2
IMAGE="cirros-0.3.5-x86_64-disk"
FLAVOR="cirros256"
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
VOL_NAME=extra_space
VOL_SIZE=1  #1GB

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


# Creates a keypair
create_keypair(){
  openstack keypair create $KEYPAIR > ~/.ssh/${KEYPAIR} || { echo "failed to create keypair $KEYPAIR" >&2; exit 1; }
  echo "Created Keypair $KEYPAIR"
  chmod 600 ~/.ssh/${KEYPAIR} 
}

# Deletes the keypair
delete_keypair(){
  openstack keypair delete $KEYPAIR || { echo "failed to delete keypair $KEYPAIR" >&2; }
  echo "Deleted Keypair $KEYPAIR"
  rm  ~/.ssh/${KEYPAIR} 
}

# Create a network
create_network(){
  local netname=$1
  openstack network create $netname || { echo "failed to create network $netname" >&2; exit 1; }
  echo "Created network $netname"
}

# Delete a network
delete_network(){
  local netname=$1
  openstack network delete $netname || { echo "failed to delete network $netname" >&2; }
  echo "Deleted network $netname"
}

# Create a subnet
create_subnet(){
  local netname=$1
  local subnetname=$2
  local cidr=$3
  openstack subnet create --subnet-range $cidr --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 \
                          --network $netname $subnetname || { echo "failed to create subnet $subnetname" >&2; exit 1; }
  echo "Created subnet $subnetname"
}

# Delete a subnet
delete_subnet(){
  local subnetname=$1
  openstack subnet delete $subnetname || { echo "failed to delete subnet $subnetname" >&2; }
  echo "Deleted subnet $subnetname"
}

# Create a router
create_router(){
  local routername=$1
  openstack router create $routername || { echo "failed to create router $routername" >&2; exit 1; }
  echo "Created router $routername"
}

# Delete a router
delete_router(){
  local routername=$1
  openstack router delete $routername || { echo "failed to delete router $routername" >&2; }
  echo "Deleted router $routername"
}

# Add a router interface to a subnet
add_router_interface(){
  local routername=$1
  local subnetname=$2
  openstack router add subnet $routername $subnetname || { echo "failed to add router intf to subnet $subnetname" >&2; exit 1; }
  echo "Added router $routername interface to subnet $subnetname"
}

# Remove a router interface from a subnet
remove_router_interface(){
  local routername=$1
  local subnetname=$2
  openstack router remove subnet $routername $subnetname || { echo "failed to remove router intf from subnet $subnetname" >&2; }
  echo "Deleted router $routername interface to subnet $subnetname"
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

# Delete a security group
delete_security_group(){
  local sgname=$1
  openstack security group delete $sgname || { echo "failed to delete security group $sgname" >&2; }
  echo "Deleted security group $sgname"
}

# Create a Host Aggregate named az1 and expose a new Availability-Zone with name $AZ. Then add the compute node to this AZ
create_az(){
  openstack aggregate create --zone $AZ $AZ || { echo "failed to create Availability Zone $AZ" >&2; exit 1; }
  echo "Created the Availability Zone $AZ"
  openstack aggregate add host $AZ $COMPUTE_NODENAME || { echo "failed to add the host $COMPUTE_NODENAME to $AZ" >&2; exit 1; }
  echo "Added the compute node $COMPUTE_NODENAME to the Host Aggregate $AZ"
}

# Delete the Host Aggregate and AZ
delete_az(){
  openstack aggregate remove host $AZ $COMPUTE_NODENAME || { echo "failed to remove host $COMPUTE_NODENAME from $AZ" >&2; }
  echo "Removed the compute node $COMPUTE_NODENAME from the Host Aggregate $AZ"
  openstack aggregate delete $AZ || { echo "failed to delete the Availability Zone $AZ" >&2; }
  echo "Deleted the Availability Zone $AZ"
}

# Boot a VM, inject keypair, add a NIC to the network, set security-group and place it in an AZ
boot_vm(){
 local vm_name=$1
 local net_name=$2
 local az=$3
 openstack server create --image $IMAGE --flavor $FLAVOR --key-name $KEYPAIR --network $net_name --security-group $SG \
                         --availability-zone $az $vm_name || { echo "Failed to create the VM: $vm_name" >&2; } 
 echo "Created VM $vm_name, attached a NIC on $net_name, set security-group $SG, injected ssh-key $KEYPAIR and placed it on AZ $az"
}

# Delete a VM
delete_vm(){
  local vm_name=$1
  openstack server delete $vm_name || { echo "failed to delete the instance $vm_name" >&2; }
  echo "Deleted the instance $vm_name"
}

# Create a Volume
create_volume(){
  openstack volume create --size $VOL_SIZE $VOL_NAME || { echo "failed to create volume $VOL_NAME,SIZE=$VOL_SIZE" >&2; exit 1; }
  echo "Created Volume $VOL_NAME size=$VOL_SIZE GB"
}

# Delete a Volume
delete_volume(){
  openstack volume delete $VOL_NAME || { echo "failed to delete volume $VOL_NAME" >&2; }
  echo "Deleted Volume $VOL_NAME"
}

# Adds the Volume to VM1
add_volume(){

  echo waiting instance to boot

  while [ "$STATUS" != "ACTIVE" ]; do   STATUSLINE="$( openstack server show $VM1 | grep '| status' )" ; STATUS="$( echo $STATUSLINE | cut -d " " -f 4 )";  echo "waiting instance to boot..." ; sleep 5 ; done
  
  openstack server add volume $VM1 $VOL_NAME || { echo "failed to add volume $VOL_NAME to server $VM1" >&2; exit 1; }
  echo "Added Volume $VOL_NAME to server $VM1"
}

# Remove the Volume from VM1
remove_volume(){
  openstack server remove volume $VM1 $VOL_NAME || { echo "failed to remove volume $VOL_NAME from server $VM1" >&2; }
  echo "Removed Volume $VOL_NAME from server $VM1"
}

## Functions for creating & deleting an external provider network, subnet & floating IP address ##

# Create a flat provider external network
create_provider_external_network(){
   openstack network create --provider-physical-network $PHYSNET --provider-network-type flat --external $EXT_NET || \
          { echo "failed to create the provider external network $EXT_NET" >&2; exit 1; }
   echo "Created the provider external network $EXT_NET"
}

# Delete the provider external network
delete_provider_external_network(){
   openstack network delete $EXT_NET || { echo "failed to delete the external network $EXT_NET" >&2; }
   echo "Deleted the provider external network $EXT_NET"
}

# Create external subnet
create_external_subnet() {
   openstack subnet create --subnet-range $EXT_NET_CIDR --gateway $EXT_GATEWAY --no-dhcp --allocation-pool \
                           start=$ALLOCATION_POOL_START,end=$ALLOCATION_POOL_END --network $EXT_NET \
                           $EXT_SUBNET || { echo "failed to create the external subnet $EXT_SUBNET" >&2; exit 1; }
   echo "Created external subnet $EXT_SUBNET"
}

# Delete the external subnet
delete_external_subnet(){
   openstack subnet delete $EXT_SUBNET || { echo "failed to delete the external subnet $EXT_SUBNET" >&2; }
   echo "Deleted external subnet $EXT_SUBNET"
}

# Set router's gateway on the external network
set_router_gateway(){
    local router_name=$1
    openstack router set --external-gateway $EXT_NET $router_name || { echo "failed to set the external gateway $EXT_NET" >&2; exit 1; }
    echo "Set external gateway $EXT_NET on router $router_name"
}

# Unset router's gateway on the external network
unset_router_gateway(){
    local router_name=$1
    openstack router unset --external-gateway $router_name || { echo "failed to unset the router $router_name external gateway" >&2; }
    echo "Unset external gateway $EXT_NET on router $router_name"
}

# Allocate a floating IP address on the public network
allocate_floating_ip(){
    openstack floating ip create --floating-ip-address $FLOATING_IP $EXT_NET || \
                   { echo "failed to allocate floating ip $FLOATING_IP" >&2; exit 1; }
    echo "Allocated Floating IP address $FLOATING_IP on external network $EXT_NET"
}

# Delete an allocated floating IP address
delete_floating_ip(){
   openstack floating ip delete $FLOATING_IP || { echo "failed to delete floating ip address $FLOATING_IP" >&2; }
   echo "Deleted floating ip address $FLOATING_IP"
}

# Add the floating IP address to an instance
add_floating_ip(){
  local vm_name=$1
  
  
echo waiting instance to boot


  while [ "$STATUS" != "ACTIVE" ]; do   STATUSLINE="$( openstack server show $vm_name | grep '| status' )" ; STATUS="$( echo $STATUSLINE | cut -d " " -f 4 )";  echo "waiting instance to boot..." ; sleep 5 ; done
  
  
  openstack server add floating ip $vm_name $FLOATING_IP || { echo "failed to add floating ip $FLOATING_IP to server $vm_name" >&2; exit 1; }
  echo "Added the floating ip address $FLOATING_IP to the instance $vm_name"
}

# Remove a floating IP address from an instance
remove_floating_ip(){
  local vm_name=$1
  openstack server remove floating ip $vm_name $FLOATING_IP || { echo "failed to remove floating ip $FLOATING_IP from server $vm_name" >&2; }
  echo "Removed the floating ip address $FLOATING_IP from the instance $vm_name"
}


### Cleanup if we are asked to do so ####
if (( CLEANUP )); then
  echo "Cleaning up.."
  delete_keypair
  remove_volume
  remove_floating_ip $VM1
  delete_vm $VM1
  delete_floating_ip
  delete_vm $VM2
  delete_volume
  delete_security_group $SG
  unset_router_gateway $ROUTER
  remove_router_interface $ROUTER $SUBNET1
  remove_router_interface $ROUTER $SUBNET2
  delete_router $ROUTER
  delete_subnet $SUBNET1
  delete_subnet $SUBNET2
  delete_external_subnet
  delete_network $NET1
  delete_network $NET2
  delete_provider_external_network
  delete_az
fi

### Create new resources, if we are asked to do so ###
if (( CREATE )); then
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
 boot_vm $VM1 $NET1 nova  # Boot the first VM on NET1 and AZ named nova (default) (i.e. place VM1 on the controller)
 boot_vm $VM2 $NET2 $AZ  # Boot the second VM on NET2 and in AZ=az2 (i.e. place VM2 on the compute node)
 create_volume   # Allocate some storage space
 add_volume      # Attach the storage volume to $VM1
 add_floating_ip $VM1   # Add a floating ip address to $VM1
fi
