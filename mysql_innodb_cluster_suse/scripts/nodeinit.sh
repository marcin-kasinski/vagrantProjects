IP=$1

MYSQL_PASS=secret
echo $IP

echo I am provisioning ...


sudo zypper install -y mysql-community-server
sudo zypper install -y mysql-shell



sudo zypper install -y /tmp/mysql-shell-1.0.11-1.sles12.x86_64.rpm