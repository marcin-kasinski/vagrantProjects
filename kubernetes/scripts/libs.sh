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
        imagePullPolicy: Always	/g'   | kubectl apply -f -

}

