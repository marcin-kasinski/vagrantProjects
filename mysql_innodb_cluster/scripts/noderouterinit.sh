IP=$1

MYSQL_PASS=secret
echo $IP

echo I am provisioning ...

#sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts

#sudo sh -c "echo '192.168.33.10 openstackmaster' >> /etc/hosts"

sudo sh -c "echo '192.168.44.10 mysqlnode1' >> /etc/hosts"
sudo sh -c "echo '192.168.44.11 mysqlnode2' >> /etc/hosts"
sudo sh -c "echo '192.168.44.12 mysqlnode3' >> /etc/hosts"
sudo sh -c "echo '192.168.44.13 mysqlrouter' >> /etc/hosts"



echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

sudo apt update

sudo apt install -y python

sudo apt-get install -y python-software-properties
sudo apt-get install -y software-properties-common

sudo wget http://dev.mysql.com/get/mysql-apt-config_0.8.9-1_all.deb
sudo DEBIAN_FRONTEND=noninteractive dpkg -i ./mysql-apt-config_0.8.9-1_all.deb
sudo apt-get update


sudo apt install -y mysql-router

#sudo mysqlrouter --bootstrap root@mysqlnode1:3306 --user=mysqlrouter
#sudo mysqlrouter &

echo "End provisioning"
