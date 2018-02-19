IP=$1

echo $IP

echo I am provisioning ...

#sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts

#sudo sh -c "echo '192.168.33.10openstackmaster' >> /etc/hosts"


echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

sudo apt update

sudo apt install mc -y 

sudo apt-get install -y python-software-properties
sudo apt-get install -y  software-properties-common
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA

echo "# Codership Repository (Galera Cluster for MySQL)" >>galera.list
echo "deb http://releases.galeracluster.com/mysql-wsrep-5.6/ubuntu xenial main" >>galera.list
echo "deb http://releases.galeracluster.com/galera-3/ubuntu xenial main" >>galera.list

sudo cp galera.list /etc/apt/sources.list.d/galera.list

echo "# Prefer Codership repository" >>galera.pref
echo "Package: *" >>galera.pref
echo "Pin: origin releases.galeracluster.com" >>galera.pref
echo "Pin-Priority: 1001" >>galera.pref

sudo cp galera.pref /etc/apt/preferences.d/galera.pref

sudo apt-get update

#sudo apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.6


sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-common mysql-server
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.6
sudo mysql -h127.0.0.1 -P3306 -uroot -e"UPDATE mysql.user SET password = PASSWORD('secret') WHERE user = 'root'"

sudo cp /vagrant/files/galera.cnf /etc/mysql/conf.d/galera.cnf

#replace
sudo sed -i -e 's/{IP}/'"$IP"'/g' /etc/mysql/conf.d/galera.cnf

HOSTNAME=`hostname`
sudo sed -i -e 's/{NODENAME}/'"$HOSTNAME"'/g' /etc/mysql/conf.d/galera.cnf

#Na pierwszym
#sudo /etc/init.d/mysql start --wsrep-new-cluster

#Na pozosta³ych
#sudo systemctl start mysql


# mysql -u root -psecret
#mysql -u root -psecret -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
#mysql -u root -psecret -e "use testmkusers; select * from users;"
#mysql -u root -psecret -e "Create database tstMK"





