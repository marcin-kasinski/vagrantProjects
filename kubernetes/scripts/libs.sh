
CLIPASS="secret"

createCA()
{
openssl req -new -newkey rsa:4096 -days 3650 -x509 -subj "/CN=Kafka-CA/OU=it/O=itzone/C=PL" -keyout /tmp/ca-key -out /tmp/ca-cert -nodes -passin pass:$CLIPASS

cat /tmp/ca-cert
cat /tmp/ca-key
keytool -printcert -v -file /tmp/ca-cert


#test
echo |
  openssl s_client -connect www.google.com:443 2>/dev/null |
  openssl x509 -noout -text -certopt no_header,no_version,no_serial,no_signame,no_pubkey,no_sigdump,no_aux -subject -nameopt multiline -issuer


}

createServerCert()
{

local host=$1
shorthostname=`echo $host | cut -d "." -f 1`

serveralias=$host
#serveralias=$shorthostname
#serveralias=localhost

#create server keypair
#keytool -genkeypair -dname "cn=$host, ou=it, o=itzone, c=PL"  -keystore /tmp/keystore-$shorthostname.jks -alias $serveralias -validity 3600 -storetype pkcs12  -keyalg RSA -storepass $CLIPASS -keypass $CLIPASS
keytool -genkeypair -dname "cn=$host, ou=it, o=itzone, c=PL"  -keystore /tmp/keystore-$shorthostname.jks -alias $serveralias -validity 3600 -storetype pkcs12 -storepass $CLIPASS -keypass $CLIPASS

#add ca to truststore
keytool -keystore /tmp/keystore-$shorthostname.jks -alias CARoot -import -file /tmp/ca-cert -storepass $CLIPASS  -noprompt
keytool -keystore /tmp/truststore-$shorthostname.jks -alias CARoot -import -file /tmp/ca-cert -storepass $CLIPASS  -noprompt
keytool -list -keystore /tmp/truststore-$shorthostname.jks -v -storepass $CLIPASS | grep "Owner: "

# create a certification request file, to be signed by the CA
keytool -keystore /tmp/keystore-$shorthostname.jks -certreq -file /tmp/cert-sign-request-$shorthostname -alias $serveralias -storepass $CLIPASS -keypass $CLIPASS

#sign it with the CA:
openssl x509 -req -CA /tmp/ca-cert -CAkey /tmp/ca-key -in /tmp/cert-sign-request-$shorthostname -out /tmp/cert-sign-request-signed-$shorthostname -days 3650 -CAcreateserial -passin pass:$CLIPASS

#print cert request
openssl req -noout -text -in /tmp/cert-sign-request-$shorthostname

#print cert
keytool -printcert -v -file /tmp/cert-sign-request-signed-$shorthostname

#import signed certificate into the keystore
keytool -keystore /tmp/keystore-$shorthostname.jks -alias $serveralias -import -file /tmp/cert-sign-request-signed-$shorthostname -storepass $CLIPASS

#listing keys
keytool -list -keystore /tmp/keystore-$shorthostname.jks -v -storepass $CLIPASS | grep "Owner: \|Issuer: "

kubectl delete configmap keystore-$shorthostname.jks | true
kubectl delete configmap truststore-$shorthostname.jks | true

kubectl create configmap keystore-$shorthostname.jks -n default --from-file=/tmp/keystore-$shorthostname.jks
kubectl create configmap truststore-$shorthostname.jks -n default --from-file=/tmp/truststore-$shorthostname.jks

}


setupSSL()
{

sudo rm /tmp/key* && sudo rm /tmp/tr* && sudo rm /tmp/ce* && sudo rm /tmp/ca*

createCA
createServerCert kafka-0.k-hs.default.svc.cluster.local
createServerCert kafka-1.k-hs.default.svc.cluster.local
createServerCert kafka-2.k-hs.default.svc.cluster.local
createServerCert springbootweb-0.springbootweb-hs.default.svc.cluster.local
createServerCert springbootkafkalistener-0.springbootkafkalistener-hs.default.svc.cluster.local
}

setupkerberos()
{
POD_NAME="kerberos-"

#KERBEROSPODNAME=`kubectl get po -n default -o wide | grep $POD_NAME | grep Running `
KERBEROSPODNAME=`kubectl get po -n default -o wide | grep $POD_NAME`
KERBEROSPODNAME=`echo $KERBEROSPODNAME | cut -d " " -f 1`
echo  $KERBEROSPODNAME

while ! kubectl get po -o wide | grep $KERBEROSPODNAME | grep Running ; do   echo "waiting for kerberos IP..." ; sleep 20 ; done

KERBEROSPODIP=`kubectl get po -o wide | grep $KERBEROSPODNAME | grep Running `
KERBEROSPODIP=`echo $KERBEROSPODIP | cut -d " " -f 6`
echo $KERBEROSPODIP

while ! nc -z $KERBEROSPODIP 88; do   echo "waiting kerberos to launch ..." ; sleep 20 ; done

kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey reader@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey writer@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey admin@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey kafka/kafka-0.k-hs.default.svc.cluster.local@KAFKA.SECURE" 
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey kafka/kafka-1.k-hs.default.svc.cluster.local@KAFKA.SECURE" 
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey kafka/kafka-2.k-hs.default.svc.cluster.local@KAFKA.SECURE" 
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey zookeeper/zk-0.zk-hs.default.svc.cluster.local@KAFKA.SECURE" 
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey zookeeper/zk-1.zk-hs.default.svc.cluster.local@KAFKA.SECURE" 
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "add_principal -randkey zookeeper/zk-2.zk-hs.default.svc.cluster.local@KAFKA.SECURE" 

  
## create keytabs
  
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/reader.user.keytab reader@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/writer.user.keytab writer@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/admin.user.keytab admin@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/kafka-0.service.keytab kafka/kafka-0.k-hs.default.svc.cluster.local@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/kafka-1.service.keytab kafka/kafka-1.k-hs.default.svc.cluster.local@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/kafka-2.service.keytab kafka/kafka-2.k-hs.default.svc.cluster.local@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/zk-0.service.keytab zookeeper/zk-0.zk-hs.default.svc.cluster.local@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/zk-1.service.keytab zookeeper/zk-1.zk-hs.default.svc.cluster.local@KAFKA.SECURE"
kubectl exec $KERBEROSPODNAME -- kadmin.local -q "xst -kt /tmp/zk-2.service.keytab zookeeper/zk-2.zk-hs.default.svc.cluster.local@KAFKA.SECURE"



kubectl cp default/$KERBEROSPODNAME:/tmp/kafka-0.service.keytab /tmp/kafka-0.service.keytab
kubectl cp default/$KERBEROSPODNAME:/tmp/kafka-1.service.keytab /tmp/kafka-1.service.keytab
kubectl cp default/$KERBEROSPODNAME:/tmp/kafka-2.service.keytab /tmp/kafka-2.service.keytab

kubectl cp default/$KERBEROSPODNAME:/tmp/zk-0.service.keytab /tmp/zk-0.service.keytab
kubectl cp default/$KERBEROSPODNAME:/tmp/zk-1.service.keytab /tmp/zk-1.service.keytab
kubectl cp default/$KERBEROSPODNAME:/tmp/zk-2.service.keytab /tmp/zk-2.service.keytab


kubectl delete configmap kafka-0-service-keytab | true
kubectl delete configmap kafka-1-service-keytab | true
kubectl delete configmap kafka-2-service-keytab | true

kubectl delete configmap zk-0-service-keytab | true
kubectl delete configmap zk-1-service-keytab | true
kubectl delete configmap zk-2-service-keytab | true

kubectl create configmap kafka-0-service-keytab -n default --from-file=/tmp/kafka-0.service.keytab
kubectl create configmap kafka-1-service-keytab -n default --from-file=/tmp/kafka-1.service.keytab
kubectl create configmap kafka-2-service-keytab -n default --from-file=/tmp/kafka-2.service.keytab

kubectl create configmap zk-0-service-keytab -n default --from-file=/tmp/zk-0.service.keytab
kubectl create configmap zk-1-service-keytab -n default --from-file=/tmp/zk-1.service.keytab
kubectl create configmap zk-2-service-keytab -n default --from-file=/tmp/zk-2.service.keytab


}

setupkafkaConnect()
{

POD_NAME="kafkaconnect-0"

while ! kubectl get po -o wide | grep $POD_NAME | grep Running ; do   echo "waiting for kafka connect IP ($POD_NAME) ..." ; sleep 20 ; done

IP=`kubectl get po -o wide | grep $POD_NAME | grep Running `
IP=`echo $IP | cut -d " " -f 6`
echo $IP

while ! nc -z $IP 8083; do   echo "waiting for kafka connect pod ($POD_NAME) to launch ..." ; sleep 20 ; done

#curl -s -X POST -H "Content-Type: application/json" --data 'data here' http://$IP:8083/connectors

sleep 4

curl -XPOST --data @/vagrant/conf/kafkaconnect/mysql.json -H "Content-Type:application/json"  http://$IP:8083/connectors


curl http://$IP:8083/connectors/Mysql | jq .

}

loop_metrics()
{
while true
do
  metric_name="MKWEB_exec_time_seconds_max"	
  
  echo "$( date ) metric values for $metric_name"
  LENGTH=$( kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/$metric_name" | jq '.items | length' )
  for (( j=0; j<$LENGTH; j++ ))
  do
      #echo "loop [$j]"	
	  
	  CMD="kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/$metric_name | jq '.items[$j].describedObject.name'"
	  CMDMETRICVALUE="kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/$metric_name | jq '.items[$j].value'"
	  
	  PODNAME=$( eval $CMD )
	  #remove character
      PODNAME=${PODNAME//\"}
	  METRICVALUE=$( eval $CMDMETRICVALUE )
	  #remove character
      METRICVALUE=${METRICVALUE//\"}
	  
	  echo "$PODNAME: $METRICVALUE"
  done
  sleep 10
done

}

init_kubernetes()
{
#sudo rm -rf ~/.kube && sudo kubeadm reset && 

IP=$( ifconfig enp0s8 | grep "inet addr:" | cut -d: -f2 | awk '{ print $1}' )

#sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP  --kubernetes-version stable-1.11 --ignore-preflight-errors all|  grep "kubeadm join"  >join_command


#sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP |  grep "kubeadm join"  >join_command
#--------
#sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP  >kubeadm_join

#for weave networking
#sudo kubeadm init --pod-network-cidr 10.32.0.0/12 --apiserver-advertise-address $IP  >kubeadm_join

sudo kubeadm init --apiserver-advertise-address $IP  >kubeadm_join

cat kubeadm_join
cat kubeadm_join |  grep "kubeadm join"  >join_command

#--------

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

#taint pods on master nodes
#kubectl taint nodes --all node-role.kubernetes.io/master-

#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"



#kubectl apply -f https://raw.githubusercontent.com/fluent/fluentd-kubernetes-daemonset/master/fluentd-daemonset-elasticsearch-rbac.yaml

#kubectl patch ds fluentd -n kube-system -p='spec:
#  template:
#    spec:
#      containers:
#      - name: fluentd
#        env:
#        - name: FLUENT_UID
#          value: "0"          
#          '

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

}


createKafka()
{
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/zookeeper.yaml?$(date +%s)"  | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/zoonavigator.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kafka.yaml?$(date +%s)" | sed -e 's/  replicas: 1/  replicas: 3/g' | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kafka-manager.yaml?$(date +%s)"  | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kafka-connect.yaml?$(date +%s)"  | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kafka-connect-ui.yaml?$(date +%s)"  | kubectl apply -f -

}


configure_nfs()
{
# ----------------------------- nfs -----------------------------
sudo apt-get install -y nfs-kernel-server
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

sudo sh -c "echo '/var/nfs/kubernetes_share *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"
sudo sh -c "echo '/var/nfs/mysql *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"
sudo sh -c "echo '/var/nfs/jenkins *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports"
sudo exportfs -ra

# ----------------------------- nfs -----------------------------

}

install_cfssl() 
{


curl -OL https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -OL https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
cfssl version

}


getPodName()
{
local POD_NAME=$1
while ! kubectl get po -o wide | grep $POD_NAME | grep Running ; do   echo "waiting for pod $POD_NAME IP ..." ; sleep 20 ; done

REALPODNAME=`kubectl get po -o wide | grep $POD_NAME | grep Running `
REALPODNAME=`echo $REALPODNAME | cut -d " " -f 1`
echo $REALPODNAME
retval=$REALPODNAME
}


getPodIP()
{
local POD_NAME=$1
while ! kubectl get po -o wide | grep $POD_NAME | grep Running ; do   echo "waiting for pod $POD_NAME IP ..." ; sleep 20 ; done

PODIP=`kubectl get po -o wide | grep $POD_NAME | grep Running `
PODIP=`echo $PODIP | cut -d " " -f 6`
#echo $PODIP
retval=$PODIP
}

waitForPODPort()
{
local POD_NAME=$1
local PORT=$2

echo "waitForPODPort POD_NAME $POD_NAME, PORT $PORT"

while true
do
  #IP=$(getPodIP $POD_NAME)
  getPodIP $POD_NAME
  IP=$retval
  #echo "ip $IP"  
  nc -z $IP $PORT
  sleep 3  
  
  #echo "nc exit code = $?"

  if [ $? != 0 ]; then
     echo  "nc Error "
     #exit $ERROR_CODE
  else break   
  fi  

done

}

createRedis()
{
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/redis.yaml?$(date +%s)" | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/phpredisadmin.yaml?$(date +%s)" | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/redis-exporter.yaml?$(date +%s)" | kubectl apply -f -


}

setupRedis()
{
getPodIP redis-0
IP_0=$retval

getPodIP redis-1
IP_1=$retval

getPodIP redis-2
IP_2=$retval

getPodIP redis-3
IP_3=$retval

getPodIP redis-4
IP_4=$retval

getPodIP redis-5
IP_5=$retval


waitForPODPort $IP_0 6379
waitForPODPort $IP_1 6379
waitForPODPort $IP_2 6379
waitForPODPort $IP_3 6379
waitForPODPort $IP_4 6379
waitForPODPort $IP_5 6379

POD_NAME="redis-0"

echo "yes" | kubectl exec -it $POD_NAME -- redis-cli --cluster create --cluster-replicas 1 \
$(kubectl get pods -l app=redis -o jsonpath='{range.items[*]}{.status.podIP}:6379 ')


kubectl exec $POD_NAME -- redis-cli --cluster rebalance --cluster-use-empty-masters \
$(kubectl get pod $POD_NAME -o jsonpath='{.status.podIP}'):6379

}

setupMongodb_rs0()
{
rs_id=0

POD_NAME="mongodb-shard-rs-"$rs_id"x-0"
echo $POD_NAME

while ! kubectl get po -o wide | grep $POD_NAME | grep Running ; do   echo "waiting for mongo shard IP $POD_NAME..." ; sleep 20 ; done

MONGOSHARDPODIP=`kubectl get po -o wide | grep $POD_NAME | grep Running `
MONGOSHARDPODIP=`echo $MONGOSHARDPODIP | cut -d " " -f 6`
echo $MONGOSHARDPODIP

while ! nc -z $MONGOSHARDPODIP 27017; do   echo "waiting mongo shard $POD_NAME to launch ..." ; sleep 20 ; done

kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.status()"

kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.initiate(  {_id: \"rs-0x\", members: [{ _id : 0, host : \"mongodb-shard-rs-0x-0.mongodb-shard-rs-0x-hs.default.svc.cluster.local:27017\" }]  })"
kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.add('mongodb-shard-rs-0x-1.mongodb-shard-rs-0x-hs.default.svc.cluster.local:27017')"
kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.add('mongodb-shard-rs-0x-2.mongodb-shard-rs-0x-hs.default.svc.cluster.local:27017')"
kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.status()"

}


setupMongodb_rs1()
{
rs_id=1

POD_NAME="mongodb-shard-rs-"$rs_id"x-0"
echo $POD_NAME

while ! kubectl get po -o wide | grep $POD_NAME | grep Running ; do   echo "waiting for mongo shard IP $POD_NAME..." ; sleep 20 ; done

MONGOSHARDPODIP=`kubectl get po -o wide | grep $POD_NAME | grep Running `
MONGOSHARDPODIP=`echo $MONGOSHARDPODIP | cut -d " " -f 6`
echo $MONGOSHARDPODIP

while ! nc -z $MONGOSHARDPODIP 27017; do   echo "waiting mongo shard $POD_NAME to launch ..." ; sleep 20 ; done

kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.status()"

kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.initiate(  {_id: \"rs-1x\", members: [{ _id : 0, host : \"mongodb-shard-rs-1x-0.mongodb-shard-rs-1x-hs.default.svc.cluster.local:27017\" }]  })"
kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.add('mongodb-shard-rs-1x-1.mongodb-shard-rs-1x-hs.default.svc.cluster.local:27017')"
kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.add('mongodb-shard-rs-1x-2.mongodb-shard-rs-1x-hs.default.svc.cluster.local:27017')"
kubectl exec $POD_NAME -c mongodb-shard -- mongo --port 27017 --eval "rs.status()"

}


setupMongodb()
{

while ! kubectl get po -o wide | grep mongodb-configdb-0 | grep Running ; do   echo "waiting for mongocfg IP..." ; sleep 20 ; done

MONGOCFGPODIP=`kubectl get po -o wide | grep mongodb-configdb-0 | grep Running `
MONGOCFGPODIP=`echo $MONGOCFGPODIP | cut -d " " -f 6`
echo $MONGOCFGPODIP

while ! nc -z $MONGOCFGPODIP 27019; do   echo "waiting mongocgf to launch ..." ; sleep 20 ; done

kubectl exec mongodb-configdb-0 -c mongodb-configdb-container -- mongo --port 27019 --eval "rs.status()"
kubectl exec mongodb-configdb-0 -c mongodb-configdb-container -- mongo --port 27019 --eval "rs.initiate(  {_id: \"MyConfigRepl\",configsvr: true,members: [{ _id : 0, host : \"mongodb-configdb-0.mongodb-configdb-hs.default.svc.cluster.local:27019\" }]  })"
kubectl exec mongodb-configdb-0 -c mongodb-configdb-container -- mongo --port 27019 --eval "rs.status()"
kubectl exec mongodb-configdb-0 -c mongodb-configdb-container -- mongo --port 27019 --eval "rs.add('mongodb-configdb-1.mongodb-configdb-hs.default.svc.cluster.local:27019')"
kubectl exec mongodb-configdb-0 -c mongodb-configdb-container -- mongo --port 27019 --eval "rs.add('mongodb-configdb-2.mongodb-configdb-hs.default.svc.cluster.local:27019')"
kubectl exec mongodb-configdb-0 -c mongodb-configdb-container -- mongo --port 27019 --eval "rs.status()"


setupMongodb_rs0
setupMongodb_rs1


while ! kubectl get po -o wide | grep mongodb-router-0 | grep Running ; do   echo "waiting for mongos IP..." ; sleep 20 ; done

MONGOROUTERPODIP=`kubectl get po -o wide | grep mongodb-router-0 | grep Running `
MONGOROUTERPODIP=`echo $MONGOROUTERPODIP | cut -d " " -f 6`
echo $MONGOROUTERPODIP

while ! nc -z $MONGOROUTERPODIP 27017; do   echo "waiting mongos to launch ..." ; sleep 20 ; done

#dodanie pierwszego rs
kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo --port 27017 --eval "sh.addShard('rs-0x/mongodb-shard-rs-0x-0.mongodb-shard-rs-0x-hs.default.svc.cluster.local:27017,mongodb-shard-rs-0x-1.mongodb-shard-rs-0x-hs.default.svc.cluster.local:27017,mongodb-shard-rs-0x-2.mongodb-shard-rs-0x-hs.default.svc.cluster.local:27017','name:shard-rs-0x')"
#dodanie drugiego rs
kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo --port 27017 --eval "sh.addShard('rs-1x/mongodb-shard-rs-1x-0.mongodb-shard-rs-1x-hs.default.svc.cluster.local:27017,mongodb-shard-rs-1x-1.mongodb-shard-rs-1x-hs.default.svc.cluster.local:27017,mongodb-shard-rs-1x-2.mongodb-shard-rs-1x-hs.default.svc.cluster.local:27017','name:shard-rs-1x')"

kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo --port 27017 --eval "sh.status();"


#The default chunk size in MongoDB is 64 megabytes.
# set to 2 mb

kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017/config --eval "db.settings.save( { _id:\"chunksize\", value: 2 } );"

#enable sharding on db
kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo --port 27017 --eval "sh.enableSharding(\"mkdatabase\")"

kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017 --eval "sh.shardCollection(\"mkdatabase.myNewCollection1\", { x: 1 } )"

kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017/mkdatabase --eval "db.myNewCollection1.insertOne( { x: 3 } );"
kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017/mkdatabase --eval "db.myNewCollection1.insertOne( { x: 4 } );"
kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017/mkdatabase --eval "for (var i = 0; i < 200; i++) {    db.myNewCollection1.insertOne({ message: \"alkdfjowritoszlkfashtopjasZ>Dnvl;asutp;amxcv;khrtpjas;xvnlxfjtp;damgv;xkng;psej\", x: i });}"


kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017/mkdatabase --eval "db.adminCommand({ listShards: 1 })"
kubectl exec mongodb-router-0 -c mongodb-router-container -- mongo localhost:27017/mkdatabase --eval "db.myNewCollection1.getShardDistribution()"




}


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


setKafkaACL()
{

local user=$1
local objectName=$2
local objectType=$3
local operation=$4
objectTypeCmd='--'$objectType

echo  -------------------------------------------------------------------------------
echo setKafkaACL : user=$user, objectName=$objectName, objectType=$objectType, operation=$operation
echo  -------------------------------------------------------------------------------

echo kubectl exec kafka-0 -- bash -c "KAFKA_OPTS="" /opt/kafka/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=$zookeeper --add --allow-principal \
User:$user $operation $objectTypeCmd $objectName"


kubectl exec kafka-0 -- bash -c "KAFKA_OPTS="" /opt/kafka/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=$zookeeper --add --allow-principal \
User:$user $operation $objectTypeCmd $objectName"
}

setKafkaTopicACL()
{
local user=$1
local topic=$2
local operation=$3

echo  -------------------------------------------------------------------------------
echo setKafkaTopicACL : user=$user, topic=$topic, operation=$operation
echo  -------------------------------------------------------------------------------

setKafkaACL "$user" "$topic" "topic" "$operation"
}

setKafkaGroupACL()
{
local user=$1
local group=$2
local operation=$3

echo  -------------------------------------------------------------------------------
echo setKafkaGroupACL : user=$user, group=$group, operation=$operation
echo  -------------------------------------------------------------------------------

setKafkaACL "$user" "$group" "group" "$operation"
}

setKafkaClusterACL()
{
local user=$1
local cluster=$2
local operation=$3

echo  -------------------------------------------------------------------------------
echo setKafkaClusterACL : user=$user, cluster=$cluster, operation=$operation
echo  -------------------------------------------------------------------------------

setKafkaACL "$user" "$cluster" "cluster" "$operation"
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

#cd /tmp
#curl http://ftp.ps.pl/pub/apache/kafka/1.0.0/kafka_2.11-1.0.0.tgz | tar xvz
#/tmp/kafka_2.11-1.0.0/bin/kafka-topics.sh --list --zookeeper $KAFKAPODIP:2181

zookeeper=zk-0.zk-hs.default.svc.cluster.local:2181,zk-1.zk-hs.default.svc.cluster.local:2181,zk-2.zk-hs.default.svc.cluster.local:2181/kafka

kafka-topics.sh --create --zookeeper $zookeeper --partitions 6 --replication-factor 3 --topic fluentd-springboot-logs
kafka-topics.sh --create --zookeeper $zookeeper --partitions 6 --replication-factor 3 --topic fluentd-kubernetes-logs
kafka-topics.sh --create --zookeeper $zookeeper --partitions 6 --replication-factor 3 --topic my-topic






setKafkaClusterACL "CN=kafka-0.k-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "kafka-cluster" "--operation ClusterAction"
setKafkaClusterACL "CN=kafka-1.k-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "kafka-cluster" "--operation ClusterAction"
setKafkaClusterACL "CN=kafka-2.k-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "kafka-cluster" "--operation ClusterAction"

setKafkaTopicACL "CN=springbootkafkalistener-0.springbootkafkalistener-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "my-topic" "--operation Create --operation Describe --operation Read"
setKafkaGroupACL "CN=springbootkafkalistener-0.springbootkafkalistener-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "order" "--operation Describe --operation Read"
setKafkaTopicACL "CN=springbootkafkalistener-0.springbootkafkalistener-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "__consumer_offsets" "--operation Describe"


setKafkaClusterACL "ANONYMOUS" "kafka-cluster" "--operation Create"

setKafkaTopicACL "ANONYMOUS" "__consumer_offsets" "--operation Describe"
setKafkaGroupACL "ANONYMOUS" "group1" "--operation Describe --operation Read"
setKafkaGroupACL "ANONYMOUS" "fluent_group" "--operation Describe --operation Read"
setKafkaGroupACL "ANONYMOUS" "glogstashelk" "--operation Describe --operation Read"
#setKafkaTopicACL "ANONYMOUS" "my-topic" "--operation Describe" # nie mam pojecia czemu te uprawnienie jest potrzebnez weba
setKafkaTopicACL "ANONYMOUS" "logs" "--operation Create --operation Describe --operation Read --operation Write"
setKafkaTopicACL "ANONYMOUS" "fluentd-springboot-logs" "--operation Create --operation Describe --operation Read --operation Write"
setKafkaTopicACL "ANONYMOUS" "fluentd-kubernetes-logs" "--operation Create --operation Describe --operation Read --operation Write"

setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL "my-topic" "--operation Describe --operation Create --operation Write"
setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL "__consumer_offsets" "--operation Describe"
#setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL "logs" "--operation Describe --operation Create --operation Write"
#setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL "fluentd-logs" "--operation Describe --operation Create --operation Write"

#------------------------------- kafka init ------------------------------- 

}

setupMYSQL()
{


#------------------------------- mysql init ------------------------------- 

sudo apt install -y netcat
sudo apt install -y mysql-client 


while ! kubectl get po -o wide | grep mysql-deployment | grep Running ; do   echo "waiting for mysql IP..." ; sleep 20 ; done

MYSQLPODIP=`kubectl get po -o wide | grep mysql-deployment | grep Running `
MYSQLPODIP=`echo $MYSQLPODIP  | cut -d " " -f 6`

while ! nc -w 20 -z $MYSQLPODIP 3306; 
do
  while ! kubectl get po -o wide | grep mysql-deployment | grep Running ; do   echo "waiting for mysql IP..." ; sleep 20 ; done

  MYSQLPODIP=`kubectl get po -o wide | grep mysql-deployment | grep Running `
  MYSQLPODIP=`echo $MYSQLPODIP  | cut -d " " -f 6`
  echo $MYSQLPODIP
  echo "waiting mysql ( $MYSQLPODIP ) to launch ..." ; sleep 20 ; 
done


	echo "Found MYSQL : $MYSQLPODIP"

mysqlshow -h $MYSQLPODIP --user=root --password=secret mysql | grep -v Wildcard | grep -o test

if [ $? -gt 0 ] ; then
  echo "nie ma bazy"
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

GRAFANAPODLINE=`kubectl get po -n default -o wide | grep $GRAFANAPODNAME | grep Running`
GRAFANAPODIP=`echo $GRAFANAPODLINE | cut -d " " -f 6`
GRAFANAPODNAME=`echo $GRAFANAPODLINE | cut -d " " -f 1`
echo GRAFANA POD NAME $GRAFANAPODNAME
echo GRAFANA IP $GRAFANAPODIP

while ! nc -w 20 -z $GRAFANAPODIP 3000; do   echo "waiting grafana to launch ..." ; sleep 20 ; done

#add datasource
curl -XPOST --data @/vagrant/conf/grafanaprometheusdatasource.json -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/datasources

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_kafka_overview.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_elasticsearch.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_apps.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_mongo.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_mysql.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"Dashboard\":  $(</vagrant/conf/grafana_dashboard_redis.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana_dashboard_poland.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db




}



showDashboardIP(){

while ! kubectl get po -n kube-system -o wide | grep kubernetes-dashboard | grep Running ; do   echo "waiting for dashboard IP..." ; sleep 20 ; done

	DASHBOARDPODLINE=`kubectl get po -n kube-system -o wide | grep kubernetes-dashboard | grep Running`
	
	DASHBOARDPODNAME=`echo $DASHBOARDPODLINE  | cut -d " " -f 1`
	DASHBOARDPODIP=`echo $DASHBOARDPODLINE  | cut -d " " -f 6`
	echo Dashboard Name: $DASHBOARDPODNAME
	echo Dashboard IP $DASHBOARDPODIP
#echo "forward port"
nohup kubectl port-forward -n kube-system  $(kubectl get po -n kube-system -l k8s-app=kubernetes-dashboard -o jsonpath="{.items[0].metadata.name}") 8443:8443  > /dev/null 2>&1 &

echo "DashboardToken ..."

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}')

}

createMonitoring()
{

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/grafana.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/prometheus.yaml?$(date +%s)"   | sed -e 's/  replicas: 1/  replicas: 1/g' | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/alertmanager.yaml?$(date +%s)" | sed -e 's/  replicas: 1/  replicas: 3/g' | kubectl apply -f -


curl "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-delegator.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-reader.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-apiservice.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-service.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/resource-reader.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-deployment.yaml?$(date +%s)" | sed -e 's/imagePullPolicy: Always/\
        command:\
        - \/metrics-server\
        - --kubelet-insecure-tls\
        - --kubelet-preferred-address-types=InternalIP\
        - --v=5\
        imagePullPolicy: Always	/g'   | kubectl apply -f -

kubectl apply -f /vagrant/yml/monitoring/namespaces.yaml


#kubectl create secret generic key -n monitoring --from-file=/vagrant/conf/certs/prometheusadapter.key
kubectl create configmap key -n custom-metrics --from-file=/vagrant/conf/certs/prometheusadapter.key
kubectl create configmap crt -n custom-metrics --from-file=/vagrant/conf/certs/prometheusadapter.crt

#kubectl apply -f /vagrant/yml/monitoring/custom-metrics-api
kubectl apply -f /vagrant/yml/monitoring/manifests

kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq .
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MK_6_received_messages" | jq  '.items[].value'
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_6_received_messages" | jq  '.items[].value'
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq .
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'
kubectl api-versions

}



createHeapster()
{
# heapster
curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/grafana.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml | kubectl apply -f -

# w nowszej wersji musia�em doda� bo by�y b��dy: Failed to list *v1.Node: nodes is forbidden: User "system:serviceaccount:kube-system:heapster" cannot list nodes at the cluster scope
curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml | kubectl apply -f -


}
createIngress()
{

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

}

createMongo()
{

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mongodbcfg.yaml?$(date +%s)"  | sed -e 's/  replicas: 1/  replicas: 3/g'  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mongodbshard.yaml?$(date +%s)" | sed -e 's/  replicas: 1/  replicas: 3/g'  | kubectl apply -f -
#drugie replica set
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mongodbshard.yaml?$(date +%s)" | sed -e 's/  replicas: 1/  replicas: 3/g; s/rs-0x/rs-1x/g; '  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mongodbrouter.yaml?$(date +%s)"  | kubectl apply -f -
}

createMyapps()
{
# moje aplikacje
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/jenkins.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/artifactory.yaml | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/phpmyadmin_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/nginx.yaml?$(date +%s)"  | kubectl apply -f -

#curl http://es:9200/_cluster/health
#curl http://es:9200/_cat/indices?v
#curl http://es:9200/_nodes
#curl http://es:9200/_cluster/stats?human&pretty

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elasticsearch.yaml?$(date +%s)" | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elastic-exporter.yaml?$(date +%s)" | kubectl apply -f -

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/logstash.yaml?$(date +%s)" | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kibana.yaml?$(date +%s)" | kubectl apply -f -

curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/rabbitmq_dp_and_service.yaml | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootZipkin_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootRabbitMQListener_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootkafkalistener.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootmicroservice.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootweb.yaml?$(date +%s)"  | kubectl apply -f -


}


