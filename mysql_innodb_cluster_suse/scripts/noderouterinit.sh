IP=$1

echo $IP

echo I am provisioning ...

#sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts

#sudo sh -c "echo '192.168.33.10 openstackmaster' >> /etc/hosts"

sudo sh -c "echo '192.168.44.10 mysqlnode1' >> /etc/hosts"
sudo sh -c "echo '192.168.44.11 mysqlnode2' >> /etc/hosts"
sudo sh -c "echo '192.168.44.12 mysqlnode3' >> /etc/hosts"
sudo sh -c "echo '192.168.44.13 mysqlrouter' >> /etc/hosts"

wget https://dev.mysql.com/get/mysql57-community-release-sles12-11.noarch.rpm -O /tmp/mysql57-community-release-sles12-11.noarch.rpm

sudo rpm -ivh /tmp/mysql57-community-release-sles12-11.noarch.rpm

sudo zypper --non-interactive --no-gpg-checks --gpg-auto-import-keys ref 

sudo zypper --non-interactive --no-gpg-checks install mysql-router


#sudo mysqlrouter --bootstrap root@mysqlnode1:3306 --user=mysqlrouter
#sudo mysqlrouter &