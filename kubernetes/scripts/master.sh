#!/bin/bash
source /vagrant/scripts/libs.sh


echo I am provisioning...
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioning "$1

#ls | grep pattern | sed -e 's/^/prefix/' -e 's/$/suffix/'


configure_nfs
init_kubernetes

install_cfssl

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# https://github.com/kubernetes/dashboard/wiki/Creating-sample-user
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

showDashboardIP

createMyapps


setupMYSQL
setupkafka
setup_kafkaConnect

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/postfix.yaml?$(date +%s)"  | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fakesmtp.yaml?$(date +%s)"  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/prometheus.yaml?$(date +%s)"   | sed -e 's/  replicas: 1/  replicas: 1/g' | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/alertmanager.yaml?$(date +%s)" | sed -e 's/  replicas: 1/  replicas: 3/g' | kubectl apply -f -

#curl "https://raw.githubusercontent.com/coreos/prometheus-operator/master/bundle.yaml?$(date +%s)"  | kubectl apply -f -
	
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootRabbitMQListener_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/SpringBootKafkaListener_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootmicroservice.yaml?$(date +%s)"  | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootweb.yaml?$(date +%s)"  | kubectl apply -f -

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

# w nowszej wersji musia�em doda� bo by�y b��dy: Failed to list *v1.Node: nodes is forbidden: User "system:serviceaccount:kube-system:heapster" cannot list nodes at the cluster scope
curl https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml | kubectl apply -f -


setupMonitoring
   
# moje poprawki : dashboard
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/dashboard-service-ingress.yaml | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/grafana.yaml?$(date +%s)"  | kubectl apply -f -

#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/influxdb-ingress.yaml | kubectl apply -f -
#curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/graphite.yaml | kubectl apply -f -


echo ">>>>>>>>>>>>>>>>>>>>>>>>>>machine provisioned "$1
 
configureGrafana
setupMongodb
showCustomService
showDashboardIP
 
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'
 