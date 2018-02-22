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
#sudo wget http://dev.mysql.com/get/mysql-apt-config_0.8.4-1_all.deb
sudo DEBIAN_FRONTEND=noninteractive dpkg -i ./mysql-apt-config_0.8.9-1_all.deb
sudo apt-get update


sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASS"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASS"
sudo apt install -y mysql-server mysql-shell

#sudo sed -i -e 's/127.0.0.1/'"$IP"'/g' /etc/mysql/mysql.conf.d/mysqld.cnf 
sudo sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf 

sudo systemctl restart mysql.service

mysql -u root -psecret -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION; FLUSH PRIVILEGES"

echo "End provisioning"
#sudo mysqlsh


#dba.checkInstanceConfiguration('root@localhost:3306');
#dba.configureLocalInstance('root@192.168.44.10:3306', {clusterAdmin: 'root@192.168.44.10%',clusterAdminPassword: 'secret'});
#dba.configureLocalInstance('root@localhost:3306', {password: 'secret'});
#dba.configureLocalInstance('root@localhost:3306');
#shell.connect('root@192.168.44.10:3306', 'secret');
#var cluster = dba.createCluster('myCluster');
#cluster.status();
#cluster.addInstance('root@192.168.44.11:3306', {password: 'secret'});
#cluster.addInstance('root@192.168.44.12:3306', {password: 'secret'});
#cluster.status();
