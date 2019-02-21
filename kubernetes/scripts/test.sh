#!/bin/bash
source /vagrant/scripts/libs.sh

createJaegerOperator 2>&1 | tee ~/createJaegerOperator.log

setupIstio 2>&1 | tee ~/setupIstio.log
#createVistio 2>&1 | tee ~/createVistio.log
createKiali 2>&1 | tee ~/createKiali.log

setupSSL apps 2>&1 | tee ~/setupSSL.log
#install_cfssl

createKafka 2>&1 | tee ~/createKafka.log

setupkafka 2>&1 | tee ~/setupkafka.log

createIngress 2>&1 | tee ~/createIngress.log

#createHeapster 2>&1 | tee ~/createHeapster.log

#createMyBackendServers 2>&1 | tee ~/createMyBackendServers.log
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elasticsearch.yaml?$(date +%s)" | kubectl apply -f -
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/rabbitmq.yaml | kubectl apply -f -

#createMyapps 2>&1 | tee ~/createMyapps.log
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootweb.yaml?$(date +%s)"  | kubectl apply -n apps -f -
  
# moje poprawki : dashboard
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/dashboard-service-ingress.yaml | kubectl apply -f -



finish

echo checking networking
kubectl exec -it -n default kafka-0 -- sh -c "curl -s -o /dev/null -w "%{http_code}" https://www.onet.pl/"