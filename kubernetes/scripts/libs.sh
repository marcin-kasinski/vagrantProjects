setupMonitoring()
{

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
kubectl create configmap key -n monitoring --from-file=/vagrant/conf/certs/prometheusadapter.key
kubectl create configmap crt -n monitoring --from-file=/vagrant/conf/certs/prometheusadapter.crt

kubectl apply -f /vagrant/yml/monitoring/custom-metrics-api

kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq .
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MK_6_received_messages" | jq  '.items[].value'
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_6_received_messages" | jq  '.items[].value'
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq .
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'
kubectl api-versions
}

