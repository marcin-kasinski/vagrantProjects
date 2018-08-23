forwardingressport()
{

while ! kubectl get po -n ingress-nginx -o wide | grep nginx | grep k8snode1 | grep Running ; do   echo "waiting for ingress-nginx IP..." ; sleep 20 ; done

INGRESSPODNAME=`kubectl get po -n ingress-nginx -o wide | grep nginx | grep k8snode1 | grep Running `

echo  $INGRESSPODNAME

INGRESSPODNAME=`echo $INGRESSPODNAME | cut -d " " -f 1`
echo  $INGRESSPODNAME

INGRESSPODPORT=`kubectl get svc -n ingress-nginx ingress-nginx|grep ingress-nginx `
INGRESSPODPORT=`echo $INGRESSPODPORT | cut -d ":" -f 2`
INGRESSPODPORT=`echo $INGRESSPODPORT | cut -d "/" -f 1`
echo  $INGRESSPODPORT


}

setupkafka()
{

          #------------------------------- kafka init ------------------------------- 
     
      sudo apt install -y openjdk-8-jdk
      while ! kubectl get po -o wide | grep kafka-0 | grep Running ; do   echo "waiting for kafka IP..." ; sleep 20 ; done


      KAFKAPODIP=`kubectl get po -o wide | grep kafka-0 | grep Running `
      echo $KAFKAPODIP
      KAFKAPODIP=`echo $KAFKAPODIP  | cut -d " " -f 6`
      echo $KAFKAPODIP

      while ! nc -z $KAFKAPODIP 9092; do   echo "waiting kafka to launch ..." ; sleep 20 ; done


		cd /tmp
		curl http://ftp.ps.pl/pub/apache/kafka/1.0.0/kafka_2.11-1.0.0.tgz | tar xvz
		/tmp/kafka_2.11-1.0.0/bin/kafka-topics.sh --list --zookeeper $KAFKAPODIP:2181


          #------------------------------- kafka init ------------------------------- 

}

setupMYSQL()
{


      #------------------------------- mysql init ------------------------------- 
            
      sudo apt install -y netcat
      sudo apt install -y mysql-client 
            

while ! kubectl get po -o wide | grep mysql | grep Running ; do   echo "waiting for mysql IP..." ; sleep 20 ; done

while ! nc -w 20 -z $MYSQLPODIP 3306; 
do
  while ! kubectl get po -o wide | grep mysql | grep Running ; do   echo "waiting for mysql IP..." ; sleep 20 ; done

  MYSQLPODIP=`kubectl get po -o wide | grep mysql | grep Running `
  MYSQLPODIP=`echo $MYSQLPODIP  | cut -d " " -f 6`
  echo $MYSQLPODIP
  echo "waiting mysql ( $MYSQLPODIP ) to launch ..." ; sleep 20 ; 
done


	echo "Found MYSQL : $MYSQLPODIP"

      mysqlshow -h $MYSQLPODIP --user=root --password=secret mysql | grep -v Wildcard | grep -o test

         if [ $? -gt 0 ] ; then
          echo "nie ma bazy"
          
          
          
          #echo $SQL >microserviceinit.sql
          #mysql -h $MYSQLPODIP  -uroot -psecret  --port 3306  mysql -e "$SQL"
          mysql -h $MYSQLPODIP  -uroot -psecret  --port 3306  mysql < /vagrant/sql/microserviceinit.sql
        else
          echo "jest baza"
    	fi
    
    
    
          #------------------------------- mysql init ------------------------------- 


}


showCustomService()
{

NGINXPODNAME="nginx"

while ! kubectl get po -n default -o wide | grep $NGINXPODNAME | grep Running ; do   echo "waiting for nginx IP..." ; sleep 20 ; done

NGINXPODIP=`kubectl get po -n default -o wide | grep $NGINXPODNAME | grep Running`
NGINXPODIP=`echo $NGINXPODIP | cut -d " " -f 6`

while ! nc -w 20 -z $NGINXPODIP 80; do   echo "waiting nginx to launch ..." ; sleep 20 ; done


echo "Adresy uslug"

curl $NGINXPODIP | grep "<a"
}

configureGrafana(){


GRAFANAPODNAME="grafana"

while ! kubectl get po -n default -o wide | grep $GRAFANAPODNAME | grep Running ; do   echo "waiting for Grafana IP..." ; sleep 20 ; done

GRAFANAPODIP=`kubectl get po -n default -o wide | grep $GRAFANAPODNAME | grep Running`
GRAFANAPODIP=`echo $GRAFANAPODIP | cut -d " " -f 6`

echo GRAFANA IP $GRAFANAPODIP

      while ! nc -w 20 -z $GRAFANAPODIP 3000; do   echo "waiting grafana to launch ..." ; sleep 20 ; done

#add datasource
curl -XPOST --data @/vagrant/conf/grafanaprometheusdatasource.json -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/datasources


DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_kafka_overview.json)     }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_elasticsearch.json)     }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_apps.json)     }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_mysql.json)     }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db


}



showDashboardIP(){

while ! kubectl get po -n kube-system -o wide | grep kubernetes-dashboard | grep Running ; do   echo "waiting for dashboard IP..." ; sleep 20 ; done

	DASHBOARDPODIP=`kubectl get po -n kube-system -o wide | grep kubernetes-dashboard | grep Running`
	
	DASHBOARDPODNAME=`echo $DASHBOARDPODIP  | cut -d " " -f 1`
	DASHBOARDPODIP=`echo $DASHBOARDPODIP  | cut -d " " -f 6`
	echo Dashboard Name: $DASHBOARDPODNAME
	echo Dashboard IP $DASHBOARDPODIP

#sudo kubectl port-forward  -n kube-system $DASHBOARDPODNAME 8443:8443 &

      echo "DashboardToken ..."
      
      kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')


}


  echo I am provisioning...
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1
      
      #ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'
      
      
      # ----------------------------- nfs -----------------------------
      sudo apt-get install nfs-kernel-server
      # katalog dla joina:

      sudo mkdir /var/nfs/kubernetes_share -p
      sudo chown nobody:nogroup /var/nfs/kubernetes_share
      
      sudo mkdir /var/nfs/mysql -p
      sudo chown nobody:nogroup /var/nfs/mysql
      
      sudo mkdir /var/nfs/jenkins -p
      sudo chown nobody:nogroup /var/nfs/jenkins

      #Jesli jenkins nie moze zapisywac do pliku
      sudo chown -R 1000:1000 /var/nfs/jenkins
      sudo chown -R 1000:1000 /var/nfs/mysql

      
      
      sudo sh -c "echo '/var/nfs/kubernetes_share    *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"      
      sudo sh -c "echo '/var/nfs/mysql    *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"      
      sudo sh -c "echo '/var/nfs/jenkins    *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"      
      sudo exportfs -ra

      # ----------------------------- nfs -----------------------------      
            
      #sudo rm -rf ~/.kube && sudo kubeadm reset && 
      
      
      IP=$( ifconfig enp0s8 | grep "inet addr:" | cut -d: -f2 | awk '{ print $1}' )
      
      sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP |  grep "kubeadm join"  >join_command
      
      echo $IP >master_IP
      sudo cp master_IP /var/nfs/kubernetes_share/master_IP
      
      sudo cp join_command /var/nfs/kubernetes_share/join_command
      JOIN_COMMAND="$( sudo cat /var/nfs/kubernetes_share/join_command )"
      	   
       echo "sudo "$JOIN_COMMAND > join_command_sudo

      sudo cp join_command_sudo /var/nfs/kubernetes_share/join_command_sudo
      
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>CREATING CONF "

       mkdir -p $HOME/.kube
       sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
       sudo chown $(id -u):$(id -g) $HOME/.kube/config

	  mkdir -p /home/vagrant/.kube
      sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
      sudo chown vagrant:vagrant /home/vagrant/.kube/config


      #copy to NFS
      sudo cp -i /etc/kubernetes/admin.conf /var/nfs/kubernetes_share/


      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>CREATING CONF"

      kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

      # https://github.com/kubernetes/dashboard/wiki/Creating-sample-user
	  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

      showDashboardIP

      # moje aplikacje
      curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/jenkins_dp_and_service.yaml | kubectl apply -f -

      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/zookeeper_ss.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/zoonavigator.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kafka_ss.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kafka-manager.yaml?$(date +%s)"  | kubectl apply -f -

      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mysql_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mysql_prometheus_exporter.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/phpmyadmin_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -

      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/nginx_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -

	  #curl 'elasticsearch-logging:9200/_cat/indices?v'
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elasticsearch.yaml?$(date +%s)" | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elastic-exporter.yaml?$(date +%s)" | kubectl apply -f -

      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/logstash.yaml?$(date +%s)" | kubectl apply -f -

      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kibana.yaml?$(date +%s)" | kubectl apply -f -

      curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/rabbitmq_dp_and_service.yaml | kubectl apply -f -

      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootZipkin_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -


setupMYSQL
setupkafka
          
          #moje
      #curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/prometheus.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/prometheus_ss.yaml?$(date +%s)"  | kubectl apply -f -

		#prometheus-operator
	  #curl "https://raw.githubusercontent.com/coreos/prometheus-operator/master/bundle.yaml?$(date +%s)"  | kubectl apply -f -
	
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootRabbitMQListener_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootKafkaListener_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootMicroservice.yaml?$(date +%s)"  | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootWebdp_and_service.yaml?$(date +%s)"  | kubectl apply -f -

      # ingress
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/namespace.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/default-backend.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/configmap.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/tcp-services-configmap.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/udp-services-configmap.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/rbac.yaml | kubectl apply -f -
      #curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml | kubectl apply -f -

      #set 3 replicas
      curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml | sed -e 's/  replicas: 1/  replicas: 3/g' | kubectl apply -f -

      curl "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml?$(date +%s)"  | kubectl apply -f -
      #curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/ingress-service-nodeport.yaml?$(date +%s)"  | kubectl apply -f -

	  kubectl patch svc -n ingress-nginx ingress-nginx  --type=json -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}]'

      # heapster
      curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/grafana.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml | kubectl apply -f -
      curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml | kubectl apply -f -
      
      # w nowszej wersji musia³em dodaæ bo by³y b³êdy: Failed to list *v1.Node: nodes is forbidden: User "system:serviceaccount:kube-system:heapster" cannot list nodes at the cluster scope
      curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml | kubectl apply -f -
      
   
      # moje poprawki : dashboard
      curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/dashboard-service-ingress.yaml | kubectl apply -f -
      curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/grafana.yaml?$(date +%s)"  | kubectl apply -f -
      
      #curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/influxdb-ingress.yaml | kubectl apply -f -
      #curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/graphite.yaml | kubectl apply -f -


      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
           
      configureGrafana
      showCustomService
      showDashboardIP
             