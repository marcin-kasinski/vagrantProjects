    echo I am provisioning node...
		
      sudo sed -i -r '/openstacknode1/ s/^(.*)$/#\1/g' /etc/hosts

	  sudo sh -c "echo '192.168.33.11      openstacknode1' >> /etc/hosts"
      
      
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
	  sudo useradd -s /bin/bash -d /opt/stack -m stack
	  sudo apt-get install sudo -y || yum install -y sudo

	  sudo sh -c "echo 'stack ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/stack"      
	  
	  
	  sudo apt update
	  sudo apt install -y python-systemd
	  sudo apt-get install git -y || sudo yum install -y git
	  
      cd /opt/stack
      sudo git clone --branch stable/pike https://git.openstack.org/openstack-dev/devstack

      #sudo cp /vagrant/controller_local.conf /opt/stack/devstack/local.conf 
      sudo cp /vagrant/compute_local.conf /opt/stack/devstack/local.conf 
      
      sudo cp /vagrant/localrc.password /opt/stack/devstack/.localrc.password 
      
      sudo chown -R stack:stack /opt/stack/devstack

      sudo -S -u stack -i /bin/bash -l -c 'cd /opt/stack/devstack ;./stack.sh'
 
      ############################ adding image ############################

      source /opt/stack/devstack/openrc admin admin
      #export OS_PASSWORD=secret
      #export OS_AUTH_URL=http://192.168.33.10/identity/v3
      #export OS_IDENTITY_API_VERSION=3

      openstack server list
 
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1  