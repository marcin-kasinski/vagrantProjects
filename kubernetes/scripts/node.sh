#!/bin/bash
source /vagrant/scripts/libs.sh

    echo I am node provisioning...
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

      #echo "Waiting kubernetes master to launch ..."  && while ! nc -z k8smaster.local 6443; do   echo "waiting for master ..." ; sleep 5 ; done
		
	  #echo "XXXXX"
	  #exit
	  
	  
	  
#		while ! nc -z k8smaster 80; do   echo "waiting for k8smaster http ..." ; sleep 20 ; done
		
#		sleep 10
#		join_command_sudo=$(curl k8smaster/join_command_sudo)
		
#		echo join_command_sudo: $join_command_sudo
#       eval $join_command_sudo




		waitforurlOK http://k8smaster/join_command_sudo

echo `date` "join kubernetes from node finished"

joincommand="$retval"


echo `date` "executing joincommand"
echo $joincommand

eval $joincommand




      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>node machine provisioned "$1
