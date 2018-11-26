

waitForNodeReady(){

		local node_name=$1

		echo "waiting for $node_name ready..."

	    while ! nc -w 3000 -z $node_name 80; do NOW=$(date +"%d.%m.%Y %T"); echo $NOW" : waiting for $node_name ready..." ;  sleep 20 ; done

}


configure_nfs()
{
# ----------------------------- nfs -----------------------------
sudo apt-get install -y nfs-kernel-server
# katalog dla joina:

sudo mkdir /var/nfs/share -p
sudo chown nobody:nogroup /var/nfs/share

#sudo mkdir /var/nfs/mysql -p
#sudo chown nobody:nogroup /var/nfs/mysql

#sudo mkdir /var/nfs/jenkins -p
#sudo chown nobody:nogroup /var/nfs/jenkins

#Jesli jenkins nie moze zapisywac do pliku
#sudo chown -R 1000:1000 /var/nfs/jenkins
#sudo chown -R 1000:1000 /var/nfs/mysql

sudo sh -c "echo '/var/nfs/share *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"
#sudo sh -c "echo '/var/nfs/mysql *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"
#sudo sh -c "echo '/var/nfs/jenkins *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"
sudo exportfs -ra

# ----------------------------- nfs -----------------------------

}
