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

  
  openstack server add volume $VM1 $VOL_NAME || { echo "failed to add volume $VOL_NAME to server $VM1" >&2; exit 1; }
  echo "Added Volume $VOL_NAME to server $VM1"
}

# Remove the Volume from VM1
remove_volume(){
  openstack server remove volume $VM1 $VOL_NAME || { echo "failed to remove volume $VOL_NAME from server $VM1" >&2; }
  echo "Remove Volume $VOL_NAME from server $VM1"
}

### Cleanup if we are asked to do so ####
if (( CLEANUP )); then
  echo "Cleaning up.."
  delete_keypair
  remove_volume
  delete_vm $VM1
  delete_vm $VM2
  delete_volume
  delete_security_group $SG
  remove_router_interface $ROUTER $SUBNET1
  remove_router_interface $ROUTER $SUBNET2
  delete_router $ROUTER
  delete_subnet $SUBNET1
  delete_subnet $SUBNET2
  delete_network $NET1
  delete_network $NET2
  delete_az
fi

### Create new resources, if we are asked to do so ###
if (( CREATE )); then
 echo "Creating virtual infrastructure..."
 create_keypair
 create_network $NET1
 create_network $NET2
 create_subnet $NET1 $SUBNET1 $NET1_CIDR
 create_subnet $NET2 $SUBNET2 $NET2_CIDR
 create_router $ROUTER
 add_router_interface $ROUTER $SUBNET1
 add_router_interface $ROUTER $SUBNET2
 create_security_group $SG
 create_az 
 boot_vm $VM1 $NET1 nova  # Boot the first VM on NET1 and AZ named nova (default) (i.e. place VM1 on the controller)
 boot_vm $VM2 $NET2 $AZ  # Boot the second VM on NET2 and in AZ=az2 (i.e. place VM2 on the compute node)
 create_volume   # Allocate some storage space
 add_volume      # Attach the storage volume to $VM1
fi
