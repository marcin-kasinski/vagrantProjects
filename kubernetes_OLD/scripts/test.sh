#!/bin/bash

source /vagrant/scripts/libs.sh
setupIstio 2>&1 | tee ~/setupIstio.log
#setupIstio1_0_7 2>&1 | tee ~/setupIstio1_0_7.log
setupJava 2>&1 | tee ~/setupJava.log
#setupSSL apps 2>&1 | tee ~/setupSSL.log

createIngress 2>&1 | tee ~/createIngress.log
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/nginx.yaml?$(date +%s)"  | kubectl apply -f -
#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/rabbitmq.yaml | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootweb.yaml?$(date +%s)"  | kubectl apply -n apps -f -

#kubectl apply -f /vagrant/yml/httpbin.yaml

#kubectl apply -n apps -f /vagrant/yml/springbootsoapservice.yaml
kubectl apply -n apps -f /vagrant/yml/springbootwebreactor.yaml


#datapower
kubectl apply -n apps -f /vagrant/yml/springbootsoapservice.yaml
createopenldap 2>&1  | tee ~/createopenldap.log
createMQ 2>&1  | tee ~/createMQ.log
createdatapower

finish
exit

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export INGRESS_NODEPORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo INGRESS_HOST $INGRESS_HOST
echo INGRESS_PORT $INGRESS_PORT
echo INGRESS_NODEPORT $INGRESS_NODEPORT
echo GATEWAY_URL $GATEWAY_URL

getPodIP springbootwebreactor apps
IP_WEB=$retval
waitForIPPort $IP_WEB 8080

#curl -I -H Host:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/status/200
#curl -I -H Host:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
log "checking internal"
#curl -I -H Host:springbootweb.apps.svc.cluster.local http://$INGRESS_HOST:$INGRESS_PORT/
# curl -H Host:springbootsoapservice.apps.svc.cluster.local http://10.44.0.10:8080/ws/countries.wsdl | grep operation
curl -H "Host: springbootwebreactor.apps.svc.cluster.local" http://$INGRESS_HOST:$INGRESS_PORT
#curl -H "Host: springbootwebreactor.apps.svc.cluster.local" localhost:30999

log "checking external"
curl -H "Host: springbootwebreactor.apps.svc.cluster.local" localhost:$INGRESS_NODEPORT

exit

createJaegerOperator 2>&1 | tee ~/createJaegerOperator.log

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