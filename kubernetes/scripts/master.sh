#!/bin/bash
source /vagrant/scripts/libs.sh

#sudo apt install -y openjdk-9-jdk
sudo apt install -y default-jdk

echo I am provisioning...
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'

setupJava 2>&1 | tee ~/setupJava.log

#configure_nfs 2>&1 | tee ~/configure_nfs.log
init_kubernetes 2>&1 | tee ~/init_kubernetes.log

installHelm 2>&1 | tee ~/installHelm.log

setupSSL 2>&1 | tee ~/setupSSL.log
#install_cfssl

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mysql.yaml?$(date +%s)"  | kubectl apply -f -

createKafka 2>&1 | tee ~/createKafka.log

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kerberos.yaml?$(date +%s)"  | kubectl apply -f -

#setupMYSQL

#setupkerberos 2>&1 | tee ~/setupkerberos.log

setupkafka 2>&1 | tee ~/setupkafka.log
#setupkafkaConnect 2>&1 | tee ~/setupkafkaConnect.log

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fakesmtp.yaml?$(date +%s)"  | kubectl apply -f -

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fluentd_shipper.yaml?$(date +%s)"  | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fluentd_indexer.yaml?$(date +%s)"  | kubectl apply -f -

createIngress	

createHeapster

createMyapps
   
# moje poprawki : dashboard
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/dashboard-service-ingress.yaml | kubectl apply -f -

#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/influxdb-ingress.yaml | kubectl apply -f -
#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/graphite.yaml | kubectl apply -f -


echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1

createMonitoring 2>&1 | tee ~/createMonitoring.log # grafana, prometheus , alertmanager, metric server and prometheus adapter
 
#createMongo 2>&1 | tee ~/createMongo.log
#createRedis 2>&1 | tee ~/createRedis.log

#setupMongodb 2>&1 | tee ~/setupMongodb.log
#setupRedis 2>&1 | tee ~/setupRedis.log

#showCustomService

#configureGrafana 2>&1  | tee ~/configureGrafana.log

#createceph 2>&1 | tee ~/createceph.log
kubectl get po --all-namespaces | grep -v Run | grep -v Completed

createceph
#createcephObjects
#createfnproject

#createKubeless
createOpenFaas 2>&1 | tee ~/createOpenFaas.log

kubectl get po --all-namespaces | grep -v Run | grep -v Completed

showDashboardIP | tee ~/showDashboardIP.log
 
#kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'

start=$(cat /tmp/start_time)
		
end=$(date +%s)

echo $end> /tmp/end_time

runtime_seconds=$((end-start))
runtime_minutes=$((runtime_seconds/ 60 ))

modulo=$((runtime_seconds % 60 ))


#echo Runtime $runtime_seconds seconds

echo Runtime $runtime_minutes minutes and $modulo seconds

