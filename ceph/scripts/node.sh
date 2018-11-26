
    echo I am node provisioning...
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

      # ----------------------------- nfs -----------------------------

      #echo "waiting NFS to launch ..."
	  #while ! nc -w 3000 -z cephadmin 111; do   echo "waiting NFS to launch ..." ; sleep 20 ; done
		
      #echo "NFS exists"

      #sudo mkdir -p /nfs/share

      #echo "mounting NFS ..."

      #while ! sudo mount cephadmin:/var/nfs/share /nfs/share; do   echo "mounting nfs again  ..." ; sleep 10 ; done
      #while ! sudo mount -o nolock,hard,timeo=10 -t nfs cephadmin:/var/nfs/share /nfs/share; do   echo "mounting nfs again  ..." ; sleep 10 ; done

      #echo "NFS mounted..."
      
      #while [ ! -f /nfs/kubernetes_share/join_command_sudo ] ; do echo "waiting for join command..." ;  sleep 20 ; done
      

      hostname=$(hostname)
      #echo  "Creating /nfs/share/$hostname"
      #sudo touch /nfs/share/$hostname
      sudo apt install -y nginx
      echo "$hostname configured ..." 
  