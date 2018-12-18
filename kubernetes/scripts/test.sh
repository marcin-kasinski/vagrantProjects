#!/bin/bash
source /vagrant/scripts/libs.sh

#createJaeger 2>&1 | tee ~/createJaeger.log

setupIstio 2>&1 | tee ~/setupIstio.log
createVistio 2>&1 | tee ~/createVistio.log
createKiali 2>&1 | tee ~/createKiali.log
createConcourse 2>&1 | tee ~/createConcourse.log
createAmbassador 2>&1 | tee ~/createAmbassador.log
setupSSL apps 2>&1 | tee ~/setupSSL.log
#install_cfssl

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mysql.yaml?$(date +%s)"  | kubectl apply -f -

istioDisableInjection
createKafka 2>&1 | tee ~/createKafka.log
istioEnableInjection

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kerberos.yaml?$(date +%s)"  | kubectl apply -f -

setupMYSQL 2>&1 | tee ~/setupMYSQL.log

#setupkerberos 2>&1 | tee ~/setupkerberos.log

setupkafka 2>&1 | tee ~/setupkafka.log
#setupkafkaConnect 2>&1 | tee ~/setupkafkaConnect.log

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fakesmtp.yaml?$(date +%s)"  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fluentd_shipper.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fluentd_indexer.yaml?$(date +%s)"  | kubectl apply -f -

createIngress	

createHeapster

istioDisableInjection 
createMyBackendServers 2>&1 | tee ~/createMyBackendServers.log
istioEnableInjection
createMyapps 2>&1 | tee ~/createMyapps.log
   
# moje poprawki : dashboard
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/dashboard-service-ingress.yaml | kubectl apply -f -

kubectl get po --all-namespaces | grep -v Running | grep -v Completed

showDashboardIP | tee ~/showDashboardIP.log
 
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'

start=$(cat /tmp/start_time)
		
end=$(date +%s)

echo $end> /tmp/end_time

runtime_seconds=$((end-start))
runtime_minutes=$((runtime_seconds/ 60 ))

modulo=$((runtime_seconds % 60 ))


#echo Runtime $runtime_seconds seconds

echo Runtime $runtime_minutes minutes and $modulo seconds

