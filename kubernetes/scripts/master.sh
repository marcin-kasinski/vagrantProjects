#!/bin/bash

source /vagrant/scripts/libs.sh

echo "master.sh START"

export PATH="$PATH:/usr/local/bin/"


KUBERNETES_FIRST_MASTER_IP="192.168.1.11"
KUBERNETES_MASTER_LOAD_BALANCER_DNS="192.168.1.20"
MASTER_NODES="k8smaster k8smaster2 k8smaster3"
NETWORK_INTERFACE="eth1"

#sudo apt install -y default-jdk

log I am provisioning...
log ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'

cd ~


#configure_nfs 2>&1 | tee ~/configure_nfs.log

setupkeepalived | tee ~/setupkeepalived.log

configure_routing 2>&1 | tee ~/configure_routing.log

init_kubernetesHA 2>&1 | tee ~/init_kubernetesHA.log
#init_kubernetes 2>&1 | tee ~/init_kubernetes.log
checkmasters | tee ~/checkmasters.log


createWeave 2>&1 | tee ~/createWeave.log
#createflannel 2>&1 | tee ~/createflannel.log

installHelm 2>&1 | tee ~/installHelm.log

#/vagrant/scripts/test.sh
#checkmasters
#exit

#createJaegerOperator 2>&1 | tee ~/createJaegerOperator.log

setupIstio 2>&1 | tee ~/setupIstio.log
#setupIstio1_0_7 2>&1 | tee ~/setupIstio1_0_6.log

#createVistio 2>&1 | tee ~/createVistio.log
#createKiali 2>&1 | tee ~/createKiali.log
#createConcourse 2>&1 | tee ~/createConcourse.log
#createAmbassador 2>&1 | tee ~/createAmbassador.log
setupJava 2>&1 | tee ~/setupJava.log
setupSSL apps 2>&1 | tee ~/setupSSL.log
#install_cfssl

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/mysql.yaml?$(date +%s)"  | kubectl apply -f -

kubectl apply -f /vagrant/yml/mysql.yaml

createKafka 2>&1 | tee ~/createKafka.log

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kerberos.yaml?$(date +%s)"  | kubectl apply -f -

#setupMYSQL 2>&1 | tee ~/setupMYSQL.log

#setupkerberos 2>&1 | tee ~/setupkerberos.log

setupkafka 2>&1 | tee ~/setupkafka.log
#setupkafkaConnect 2>&1 | tee ~/setupkafkaConnect.log

createIngress 2>&1 | tee ~/createIngress.log

#screateHeapster 2>&1 | tee ~/createHeapster.log

createMyBackendServers 2>&1 | tee ~/createMyBackendServers.log

createMyapps 2>&1 | tee ~/createMyapps.log
   
# moje poprawki : dashboard
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/dashboard-service-ingress.yaml | kubectl apply -f -

#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/influxdb-ingress.yaml | kubectl apply -f -
#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/graphite.yaml | kubectl apply -f -

#configureGrafana 2>&1  | tee ~/configureGrafana.log

createMonitoring 2>&1 | tee ~/createMonitoring.log # metric server and prometheus adapter
#createMongo 2>&1 | tee ~/createMongo.log
#createRedis 2>&1 | tee ~/createRedis.log

#setupMongodb 2>&1 | tee ~/setupMongodb.log
#setupRedis 2>&1 | tee ~/setupRedis.log

#showCustomService

#createdatapower 2>&1  | tee ~/createdatapower.log

#createopenldap 2>&1  | tee ~/createopenldap.log

#createceph
#createcephObjects 2>&1 | tee ~/createcephObjects.log

#createfnproject

#createKubeless

#createOpenFaas 2>&1 | tee ~/createOpenFaas.log
#createOpenFaasFunction 2>&1 | tee ~/createOpenFaasFunction.log

kubectl get po --all-namespaces | grep -v Running | grep -v Completed

kubeadm token create --print-join-command

#createAirflow 2>&1 | tee ~/createairflow.log

finish 2>&1 | tee ~/finish.log

checkmasters | tee ~/checkmasters.log

log checking networking
kubectl exec -it -n default kafka-0 -- sh -c "curl -s -o /dev/null -w "%{http_code}" https://www.onet.pl/"