
    echo I am node provisioning...
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1



      #echo "Waiting kubernetes master to launch ..."  && while ! nc -z k8smaster.local 6443; do   echo "waiting for master ..." ; sleep 5 ; done

      # ----------------------------- nfs -----------------------------

	  while ! nc -z k8smaster.local 111; do   echo "waiting NFS to launch ..." ; sleep 20 ; done

	  sleep 10 
      sudo mkdir -p /nfs/kubernetes_share
      sudo mount k8smaster.local:/var/nfs/kubernetes_share /nfs/kubernetes_share
      
      while [ ! -f /nfs/kubernetes_share/join_command_sudo ] ; do echo "waiting for join command..." ;  sleep 20 ; done
      
      
      JOIN_COMMAND=$(    sudo cat /nfs/kubernetes_share/join_command_sudo  )
      eval $JOIN_COMMAND
      
      
      #MASTER_IP=$( echo /nfs/kubernetes_share/master_IP )
      
      
      # ----------------------------- nfs -----------------------------


      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>node machine provisioned "$1
