      echo I am provisioning master...
      
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
       
      #cp /vagrant/controller_local.conf /home/vagrant/devstack/local.conf 
      #cp /vagrant/localrc.password /home/vagrant/devstack/.localrc.password 
      
      echo HOST_IP=192.168.1.11 >> .localrc.password
      echo ADMIN_PASSWORD=secret >> .localrc.password
      echo DATABASE_PASSWORD=secret >> .localrc.password
      echo RABBIT_PASSWORD=secret >> .localrc.password
      echo SERVICE_PASSWORD=secret >> .localrc.password
      
    
      
      sudo chown -R stack:stack /home/vagrant/devstack
     
      sudo su -c "./stack.sh" -s /bin/sh stack
 
      ############################ adding image ############################



      #source /home/vagrant/devstack/accrc/admin/admin
      source /home/vagrant/devstack/openrc admin admin
      export OS_PASSWORD=secret
      export OS_AUTH_URL=http://192.168.1.227/identity/v3
      export OS_IDENTITY_API_VERSION=3

      #cd /home/vagrant
       
      openstack server list
            
      #wget http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
      #openstack image create --disk-format qcow2 --container-format bare  --public --file /home/vagrant/xenial-server-cloudimg-amd64-disk1.img xenial-server-cloudimg-amd64
      
      #wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
      #openstack image create --disk-format qcow2 --container-format bare  --public --file /home/vagrant/CentOS-7-x86_64-GenericCloud.qcow2 CentOS-7-x86_64-GenericCloud.qcow2
      
      #wget http://cdimage.debian.org/cdimage/openstack/current/debian-9.3.3-20180105-openstack-amd64.qcow2
      #openstack image create --container-format bare --disk-format qcow2 --file /home/vagrant/debian-9.3.3-20180105-openstack-amd64.qcow2 debian-9-openstack-amd64
      
      #wget https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2
      #openstack image create --container-format bare --disk-format qcow2 --file /home/vagrant/Fedora-Cloud-Base-27-1.6.x86_64.qcow2 Fedora-Cloud-Base-27-1.6.x86_64
      
      