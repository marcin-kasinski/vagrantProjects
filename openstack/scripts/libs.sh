
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
magnum cluster-create --cluster-template k8s-cluster-template --node-count 3 k8s-cluster


#openstack coe cluster create mycluster --cluster-template k8s-cluster-template --node-count 1 --master-count 1

openstack coe cluster list

#systemctl list-units devstack@* | grep magnum
#sudo journalctl -f --unit devstack@magnum-api.service
#sudo journalctl -f --unit devstack@magnum-cond.service


}

setupNFS(){

 # ----------------------------- nfs -----------------------------
      sudo apt-get install -y nfs-kernel-server
      
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



restartFailedServices(){

local message=$1

chmod u+x /vagrant/scripts/restartfailedservices.sh
/vagrant/scripts/restartfailedservices.sh $message

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

local public_interface=$1

openstack subnet list 

openstack subnet delete public-subnet

openstack subnet delete ipv6-public-subnet

openstack subnet list 

openstack network list

openstack network delete public

openstack network list

sudo ovs-vsctl list-br

sudo ovs-vsctl list-ports br-ex 

sudo ovs-vsctl add-port br-ex $public_interface 

sudo ovs-vsctl list-ports br-ex 

sudo ip link show $public_interface 

sudo ip link set dev $public_interface up 

sudo ip link show $public_interface

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
