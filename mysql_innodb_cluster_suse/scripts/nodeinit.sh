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


#sudo zypper install -y mysql-community-server
#sudo zypper install -y mysql-shell



#sudo zypper install -y /tmp/mysql-shell-1.0.11-1.sles12.x86_64.rpm


wget https://dev.mysql.com/get/mysql57-community-release-sles12-11.noarch.rpm -O /tmp/mysql57-community-release-sles12-11.noarch.rpm



#wget https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-1.0.11-linux-glibc2.12-x86-64bit.tar.gz -O /tmp/mysql-shell-1.0.11-linux-glibc2.12-x86-64bit.tar.gz 
#wget https://dev.mysql.com/get/Downloads/MySQL-Router/mysql-router-2.1.5-linux-glibc2.12-x86-64bit.tar.gz -O /tmp/mysql-router-2.1.5-linux-glibc2.12-x86-64bit.tar.gz
#wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz -O mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz

sudo rpm -ivh /tmp/mysql57-community-release-sles12-11.noarch.rpm

sudo zypper --non-interactive --no-gpg-checks --gpg-auto-import-keys ref 

sudo zypper --non-interactive --no-gpg-checks install mysql-community-server-5.7.21-1.sles12.x86_64

# Jeœli chodzi o klucze dajemy abort


#Po zainstalowaniu musimy zmieniæ has³o

sudo /usr/sbin/rcmysql start


PASSWORD_LINE="$( sudo cat /var/log/mysql/mysqld.log | grep 'A temporary password is generated for ' )"
FIRST_PASSWORD="$( echo ${PASSWORD_LINE##* } )"
echo $FIRST_PASSWORD



mysql --connect-expired-password  -u root -p"$FIRST_PASSWORD" </vagrant/sql/init.sql



mysql -u root -p"Secretqaz@wsx123" -e "use mysql; select user, host, authentication_string from user;"
#mysql -u root -p"Secretqaz@wsx123"



sudo zypper --non-interactive --no-gpg-checks install mysql-router  mysql-shell




#sudo zypper packages -i | grep mysql-.*community


#sudo cp /tmp/mysql-shell-1.0.11-linux-glibc2.12-x86-64bit/bin/mysqlsh /usr/local/bin/mysqlsh
#sudo cp /tmp/mysql-shell-1.0.11-linux-glibc2.12-x86-64bit/bin/mysqlprovision /usr/local/bin/mysqlprovision

#sudo mysqlsh

