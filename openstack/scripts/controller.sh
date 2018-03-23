#!/bin/bash
# set -o xtrace

DEV_BRANCH="stable/pike"
#DEV_BRANCH="stable/queens"
#DEV_BRANCH="master"

# Set global variables to control the names of the resources we create
KEYPAIR=mykey
VM1=myvm1
VM2=myvm2
#IMAGE="xenial-server-cloudimg-amd64"
IMAGE="cirros-0.3.5-x86_64-disk"

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



init(){

			#sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts
			
			#sudo sh -c "echo '192.168.33.10openstackmaster' >> /etc/hosts"
			
			
			echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
			
			sudo apt-get install sudo -y || yum install -y sudo
			
			sudo apt update
			sudo apt install -y python-systemd
			sudo apt-get install git -y || sudo yum install -y git
			sudo apt-get install mc -y 

			sudo apt -y install python-dev libssl-dev libxml2-dev curl \
                 libmysqlclient-dev libxslt-dev libpq-dev git \
                 libffi-dev gettext build-essential python3-dev


}

setupMagnum(){

source devstack/openrc admin admin

openstack coe cluster template create k8s-cluster-template \
                       --image Fedora-Atomic-26-20170723.0.x86_64   \
                       --keypair $KEYPAIR \
                       --external-network public \
                       --dns-nameserver 8.8.8.8 \
                       --flavor m1.mkflavor \
                       --master-flavor m1.mkflavor \
                       --docker-volume-size 5 \
                       --network-driver flannel \
                       --coe kubernetes

source devstack/openrc admin admin
#magnum cluster-create --cluster-template k8s-cluster-template --node-count 3 k8s-cluster

openstack coe cluster list

#systemctl list-units devstack@* | grep magnum
#sudo journalctl -f --unit devstack@magnum-api.service
#sudo journalctl -f --unit devstack@magnum-cond.service


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


fix_OVS(){

#sudo pip uninstall ryu

/usr/bin/yes | sudo pip uninstall ryu

sudo pip install ryu

sudo systemctl restart devstack@q-agt

source devstack/openrc admin admin

openstack network agent list



  echo waiting OVS to boot

  while [ "$STATUS" != "UP" ]; do  STATUS="$( openstack network agent list | grep "Open vSwitch agent" | grep openstackmaster | cut -d "|" -f 7 | xargs )" ;  echo "waiting OVS to boot..." ; sleep 20 ; done

openstack network agent list


}

# Creates a keypair
create_keypair(){
  openstack keypair create $KEYPAIR > ~/.ssh/${KEYPAIR} || { echo "failed to create keypair $KEYPAIR" >&2; exit 1; }
  echo "Created Keypair $KEYPAIR"
  chmod 600 ~/.ssh/${KEYPAIR} 
}

# Create a network
create_network(){
  local netname=$1
  openstack network create $netname || { echo "failed to create network $netname" >&2; exit 1; }
  echo "Created network $netname"
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

# Create a router
create_router(){
  local routername=$1
  openstack router create $routername || { echo "failed to create router $routername" >&2; exit 1; }
  echo "Created router $routername"
}

# Add a router interface to a subnet
add_router_interface(){
  local routername=$1
  local subnetname=$2
  openstack router add subnet $routername $subnetname || { echo "failed to add router intf to subnet $subnetname" >&2; exit 1; }
  echo "Added router $routername interface to subnet $subnetname"
}

# Create a Host Aggregate named az1 and expose a new Availability-Zone with name $AZ. Then add the compute node to this AZ
create_az(){
  openstack aggregate create --zone $AZ $AZ || { echo "failed to create Availability Zone $AZ" >&2; exit 1; }
  echo "Created the Availability Zone $AZ"
  openstack aggregate add host $AZ $COMPUTE_NODENAME || { echo "failed to add the host $COMPUTE_NODENAME to $AZ" >&2; exit 1; }
  echo "Added the compute node $COMPUTE_NODENAME to the Host Aggregate $AZ"
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

# Create a Volume
create_volume(){

 local VOL_NAME=$1
 local VOL_SIZE=$2

#  openstack volume create --size $VOL_SIZE $VOL_NAME  --type LVM2|| { echo "failed to create volume $VOL_NAME,SIZE=$VOL_SIZE" >&2; exit 1; }
  openstack volume create --size $VOL_SIZE $VOL_NAME || { echo "failed to create volume $VOL_NAME,SIZE=$VOL_SIZE" >&2; exit 1; }
  echo "Created Volume $VOL_NAME size=$VOL_SIZE GB"
}

# Adds the Volume to VM1
add_volume(){


 local VOL_NAME=$1

  echo waiting instance to boot

  while [ "$STATUS" != "ACTIVE" ]; do   STATUSLINE="$( openstack server show $VM1 | grep '| status' )" ; STATUS="$( echo $STATUSLINE | cut -d " " -f 4 )";  echo "waiting instance to boot..." ; sleep 5 ; done
  
  openstack server add volume $VM1 $VOL_NAME || { echo "failed to add volume $VOL_NAME to server $VM1" >&2; exit 1; }
  echo "Added Volume $VOL_NAME to server $VM1"
}

## Functions for creating & deleting an external provider network, subnet & floating IP address ##

# Create a flat provider external network
create_provider_external_network(){
   openstack network create --provider-physical-network $PHYSNET --provider-network-type flat --external $EXT_NET || \
          { echo "failed to create the provider external network $EXT_NET" >&2; exit 1; }
   echo "Created the provider external network $EXT_NET"
}

# Create external subnet
create_external_subnet() {
   openstack subnet create --subnet-range $EXT_NET_CIDR --gateway $EXT_GATEWAY --no-dhcp --allocation-pool \
                           start=$ALLOCATION_POOL_START,end=$ALLOCATION_POOL_END --network $EXT_NET \
                           $EXT_SUBNET || { echo "failed to create the external subnet $EXT_SUBNET" >&2; exit 1; }
   echo "Created external subnet $EXT_SUBNET"
}

# Set router's gateway on the external network
set_router_gateway(){
    local router_name=$1
    openstack router set --external-gateway $EXT_NET $router_name || { echo "failed to set the external gateway $EXT_NET" >&2; exit 1; }
    echo "Set external gateway $EXT_NET on router $router_name"
}

# Allocate a floating IP address on the public network
allocate_floating_ip(){
    openstack floating ip create --floating-ip-address $FLOATING_IP $EXT_NET || \
                   { echo "failed to allocate floating ip $FLOATING_IP" >&2; exit 1; }
    echo "Allocated Floating IP address $FLOATING_IP on external network $EXT_NET"
}

# Add the floating IP address to an instance
add_floating_ip(){
  local vm_name=$1
  
  
echo waiting instance to boot


  while [ "$STATUS" != "ACTIVE" ]; do   STATUSLINE="$( openstack server show $vm_name | grep '| status' )" ; STATUS="$( echo $STATUSLINE | cut -d " " -f 4 )";  echo "waiting instance to boot..." ; sleep 5 ; done
  
  
  openstack server add floating ip $vm_name $FLOATING_IP || { echo "failed to add floating ip $FLOATING_IP to server $vm_name" >&2; exit 1; }
  echo "Added the floating ip address $FLOATING_IP to the instance $vm_name"
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

clone_GIT(){

			git clone --branch $DEV_BRANCH https://git.openstack.org/openstack-dev/devstack

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

waitForNodeReady(){

		local node_name=$1


		echo "waiting for $node_name ready..."
    
      
      	while [ ! -f /var/nfs/openstack_share/$node_name.openstack_node_ready ] ; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for $node_name ready..." ;  sleep 20 ; done

}

addImage(){

		local image_name=$1
		local image_url=$2
		
		source devstack/openrc admin admin
		

		echo "adding image $image_name from url $image_url"
		
		wget -O /tmp/$image_name.img $image_url
		
		openstack image create --disk-format qcow2  --container-format bare --public --file /tmp/$image_name.img $image_name || { echo "failed to create image $image_name" >&2; exit 1; }

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

#kopiuje lvmdriver-2
#cat /vagrant/cinder.conf >> /etc/cinder/cinder.conf

#sudo sed -i -e 's/enabled_backends = lvmdriver-1/enabled_backends = lvmdriver-1,lvmdriver-2/g' /etc/cinder/cinder.conf 
#sudo sed -i -e 's/enabled_backends = lvmdriver-1/enabled_backends = lvmdriver-2/g' /etc/cinder/cinder.conf 
#sudo sed -i -e 's/default_volume_type = lvmdriver-1/default_volume_type = LVM2/g' /etc/cinder/cinder.conf 

sudo sed -i -e 's/volume_group = stack-volumes-lvmdriver-1/volume_group = MKmyvolgroup/g' /etc/cinder/cinder.conf 



#Restart Cinder Services.

sudo systemctl restart devstack@c-api.service
sudo systemctl restart devstack@c-vol.service
sudo systemctl restart devstack@c-sch.service




openstack volume type create --public LVM2
 
openstack volume type set LVM2 --property volume_backend_name=lvmdriver-2 

cinder get-pools

#openstack volume create --size 40 40gb-vol_LVM2 --type LVM2

#openstack volume list
}

#--------------------------------------------------------------------



#init



remove_LVM_logical_volume


setupNFS


devstack/unstack.sh

#rm -rf /home/vagrant/devstack

#clone_GIT

sudo cp /vagrant/ctr_local.conf devstack/local.conf 
			
#win2linux
sed -i -e 's/\r//g' devstack/local.conf
		
cp /vagrant/localrc.password devstack/.localrc.password 

devstack/stack.sh

fix_OVS

sudo touch /var/nfs/openstack_share/openstack_stack_finished

waitForNodeReady node1


exit 0

source devstack/openrc admin admin



openstack flavor create --public m1.mkflavor --id auto --ram 8192 --disk 7 --vcpus 1 --rxtx-factor 1


#addImage xenial-server-cloudimg-amd64 "http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img"

create_security_group SSHandICMP


sudo nova-manage cell_v2 discover_hosts --verbose 

updateCinder

#neutron router-gateway-clear  router1

source devstack/openrc admin admin
openstack router unset --external-gateway router1

configureExternalNetInterface

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
 boot_vm $VM2 $NET2 $AZ  # Boot the second VM on NET2 and in AZ=az2 (i.e. place VM2 on the compute node)
create_volume "extra_space" 2  # Allocate some storage space
create_volume "30gb-vol" 30  # Allocate some storage space
 add_volume "extra_space"     # Attach the storage volume to $VM1
 add_volume "30gb-vol"
 add_floating_ip $VM2   # Add a floating ip address to $VM1

echo "setup magnum"

#setupMagnum

