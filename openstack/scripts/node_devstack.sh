IP=$1	
	
#sudo sed -i -r '/openstacknode1/ s/^(.*)$/#\1/g' /etc/hosts

#sudo sh -c "echo '192.168.33.11openstacknode1' >> /etc/hosts"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

sudo apt-get install sudo -y || yum install -y sudo

sudo apt update
sudo apt install -y python-systemd
sudo apt-get install git -y || sudo yum install -y git
sudo apt-get install mc -y 

git clone --branch stable/pike https://git.openstack.org/openstack-dev/devstack
				
sudo cp /vagrant/compute_local.conf devstack/local.conf 

#win2linux
sed -i -e 's/\r//g' devstack/local.conf

#replace
sed -i -e 's/{IP}/'"$IP"'/g' devstack/local.conf

cp /vagrant/localrc.password devstack/.localrc.password 

cd devstack
./stack.sh