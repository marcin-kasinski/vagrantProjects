   echo I am provisioning master...
            
      #sudo sed -i -r '/openstackmaster/ s/^(.*)$/#\1/g' /etc/hosts

	  #sudo sh -c "echo '192.168.33.10      openstackmaster' >> /etc/hosts"
      
      
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

	  sudo apt-get install sudo -y || yum install -y sudo

	  sudo apt update
	  sudo apt install -y python-systemd
	  sudo apt-get install git -y || sudo yum install -y git
	  sudo apt-get install mc -y 
	  
      git clone --branch stable/pike https://git.openstack.org/openstack-dev/devstack

      sudo cp /vagrant/ctr_local.conf devstack/local.conf 
      
      #win2linux
      sed -i -e 's/\r//g' devstack/local.conf
      
      cp /vagrant/localrc.password devstack/.localrc.password 
      
	  cd devstack
	  ./stack.sh

      ############################ adding image ############################

      source openrc admin admin
      
      openstack security group create SSH
	  openstack security group rule create --proto tcp --dst-port 22 SSH

      openstack security group create ICMP	  
	  openstack security group rule create --proto icmp --dst-port 0 ICMP

	  ip --oneline addr show
	  