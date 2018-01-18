      echo I am provisioning node...
      
      echo $USER
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
	  sudo useradd -s /bin/bash -d /opt/stack -m stack
	  sudo apt-get install sudo -y || yum install -y sudo
	  #sudo echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	  
	  sudo sh -c "echo 'stack ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"      
	  
	  
	  sudo apt-get install git -y || sudo yum install -y git
	  git clone https://git.openstack.org/openstack-dev/devstack

      #mkdir ~/.ssh
	  chmod 700 ~/.ssh
      echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyYjfgyPazTvGpd8OaAvtU2utL8W6gWC4JdRS1J95GhNNfQd657yO6s1AH5KYQWktcE6FO/xNUC2reEXSGC7ezy+sGO1kj9Limv5vrvNHvF1+wts0Cmyx61D2nQw35/Qz8BvpdJANL7VwP/cFI/p3yhvx2lsnjFE3hN8xRB2LtLUopUSVdBwACOVUmH2G+2BWMJDjVINd2DPqRIA4Zhy09KJ3O1Joabr0XpQL0yt/I9x8BVHdAx6l9U0tMg9dj5+tAjZvMAFfye3PJcYwwsfJoFxC8w/SLtqlFX7Ehw++8RtvomvuipLdmWCy+T9hIkl+gHYE4cS3OIqXH7f49jdJf jesse@spacey.local" >> ~/.ssh/authorized_keys
      
      cd /home/vagrant/devstack 
       
      cp /vagrant/compute_local.conf /home/vagrant/devstack/local.conf 
      cp /vagrant/localrc.password /home/vagrant/devstack/.localrc.password 
      
      sudo chown -R stack:stack /home/vagrant/devstack
     
      sudo su -c "./stack.sh" -s /bin/sh stack
 
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1