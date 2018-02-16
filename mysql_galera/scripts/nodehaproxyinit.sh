IP=$1

echo $IP

echo I am provisioning ...

#sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts

#sudo sh -c "echo '192.168.33.10openstackmaster' >> /etc/hosts"


echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

sudo apt update

sudo apt install mc -y 

sudo add-apt-repository -y ppa:vbernat/haproxy-1.5
sudo apt-get  -q -y update
sudo apt-get -qqy install haproxy

sudo cp /vagrant/files/haproxy.cfg /etc/haproxy/haproxy.cfg

sudo service haproxy stop

sudo service haproxy start