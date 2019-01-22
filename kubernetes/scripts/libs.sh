createdatapower()
{


cd ~
git clone https://github.com/ibm-datapower/datapower-tutorials.git
cd datapower-tutorials/using-datapower-in-kubernetes/


sed -i -e "s/  port 80/  port 8181/g" datapower/config/foo/foo.cfg 


kubectl create configmap datapower-config --from-file=datapower/config/ --from-file=datapower/config/foo
kubectl create configmap datapower-local-foo --from-file=datapower/local/foo

kubectl apply -f kubernetes/deployments/backend-deployment.yaml
kubectl apply -f kubernetes/deployments/datapower-deployment.yaml

sed -i -e "s/  type: LoadBalancer/  type: NodePort/g" kubernetes/services/backend-service.yaml
sed -i -e "s/  type: LoadBalancer/  type: NodePort/g" kubernetes/services/datapower-service.yaml

kubectl apply -f kubernetes/services/backend-service.yaml
kubectl apply -f kubernetes/services/datapower-service.yaml

kubectl apply -f /vagrant/yml/datapower.yaml

kubectl patch svc datapower-webui --type=json -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30777}]'


}

finish()
{
showDashboardIP | tee ~/showDashboardIP.log
 
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'

start=$(cat /tmp/start_time)
		
end=$(date +%s)

echo $end> /tmp/end_time

runtime_seconds=$((end-start))
runtime_minutes=$((runtime_seconds/ 60 ))

modulo=$((runtime_seconds % 60 ))


#echo Runtime $runtime_seconds seconds

ping onet.pl -c 4

echo Runtime $runtime_minutes minutes and $modulo seconds


}

createJaegerOperator()
{
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/io_v1alpha1_jaeger_crd.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml

kubectl apply -f /vagrant/yml/jaeger-operator.yaml

kubectl get jaeger
kubectl get pods -l jaeger=simplest

}



createJaeger()
{
#kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
kubectl apply -f /vagrant/yml/jaeger.yaml
}

#https://www.kiali.io/gettingstarted/#_getting_started_on_kubernetes
createKiali()
{

#JAEGER_URL="http://jaeger-query-istio-system.127.0.0.1.nip.io"
JAEGER_URL="http://jaeger-query.default.svc.cluster.local"
#GRAFANA_URL="http://grafana-istio-system.127.0.0.1.nip.io"
GRAFANA_URL="http://grafana.default.svc.cluster.local:3000"

VERSION_LABEL="v0.10.0"

curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/kubernetes/kiali-configmap.yaml | \
  VERSION_LABEL=${VERSION_LABEL} \
  JAEGER_URL=${JAEGER_URL}  \
  ISTIO_NAMESPACE=istio-system  \
  GRAFANA_URL=${GRAFANA_URL} envsubst | kubectl create -n istio-system -f -

#add prometheus url
curl -OL https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/kubernetes/kiali-configmap.yaml
echo "      prometheus_service_url: http://prometheus-cs.default.svc.cluster.local:9090">> kiali-configmap.yaml
cat kiali-configmap.yaml 

cat kiali-configmap.yaml | \
  VERSION_LABEL=${VERSION_LABEL} \
  JAEGER_URL=${JAEGER_URL}  \
  ISTIO_NAMESPACE=istio-system  \
  GRAFANA_URL=${GRAFANA_URL} envsubst | kubectl apply -n istio-system -f -







curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/kubernetes/kiali-secrets.yaml | \
  VERSION_LABEL=${VERSION_LABEL} envsubst | kubectl create -n istio-system -f -

curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/kubernetes/kiali.yaml | \
  VERSION_LABEL=${VERSION_LABEL}  \
  IMAGE_NAME=kiali/kiali \
  IMAGE_VERSION=${VERSION_LABEL}  \
  NAMESPACE=istio-system  \
  VERBOSE_MODE=4  \
  IMAGE_PULL_POLICY_TOKEN="imagePullPolicy: Always" envsubst | kubectl create -n istio-system -f -

kubectl patch ingress kiali -n istio-system -p='spec:
   rules:
   - host: kiali
          '


#ambassadorAnnotateService kiali istio-system 20001

}

istioEnableInjection()
{
local NAMESPACE=$1
#to enable injection
kubectl label namespace $NAMESPACE istio-injection=enabled
}

istioDisableInjection()
{
local NAMESPACE=$1

#to disable injection
kubectl label namespace $NAMESPACE "istio-injection-"
}

#
istioDisableInjectionOnObject()
{
local NAME=$1
local NAMESPACE=$2
local OBJECTTYPE=$3

echo executing kubectl patch $OBJECTTYPE -n $NAMESPACE $NAME -p "$(cat /vagrant/conf/istio/istiodisableinject.patch)"
kubectl patch $OBJECTTYPE -n $NAMESPACE $NAME -p "$(cat /vagrant/conf/istio/istiodisableinject.patch)"

}

ambassadorAnnotateService()
{
local SERVICE=$1
local NAMESPACE=$2
local PORT=$3

cp /vagrant/conf/ambassador/annotateservice.patch /tmp/"$SERVICE".patch

sed -i -e 's/{SERVICE}/'"$SERVICE"'/g' /tmp/"$SERVICE".patch
sed -i -e 's/{NAMESPACE}/'"$NAMESPACE"'/g' /tmp/"$SERVICE".patch
sed -i -e 's/{PORT}/'"$PORT"'/g' /tmp/"$SERVICE".patch

cat /tmp/"$SERVICE".patch

echo executing kubectl patch service -n $NAMESPACE $SERVICE -p "$(cat /tmp/"$SERVICE".patch)"
kubectl patch service -n $NAMESPACE $SERVICE -p "$(cat /tmp/"$SERVICE".patch)"
}

createConcourse()
{

mkdir /tmp1
ssh -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key vagrant@k8snode1 sudo mkdir /tmp1
ssh -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key vagrant@k8snode2 sudo mkdir /tmp1
ssh -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key vagrant@k8snode3 sudo mkdir /tmp1

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/concourse.yaml?$(date +%s)"  | kubectl apply -f -
kubectl apply -f /vagrant/yml/concourse.yaml

helm install stable/concourse --name concourse --set persistence.worker.storageClass=standard
# helm del --purge concourse
# kubectl delete namespace "concourse-main"



} 

createAmbassador()
{

#helm repo add datawire https://www.getambassador.io
#helm upgrade --install --wait my-release datawire/ambassador
kubectl cluster-info dump --namespace kube-system | grep authorization-mode

#kubectl apply -f https://getambassador.io/yaml/ambassador/ambassador-rbac.yaml

helm repo add datawire https://www.getambassador.io
#helm upgrade --install --wait my-release datawire/ambassador --set service.type=NodePort
#helm del --purge ambassador
helm install --name ambassador datawire/ambassador --set service.type=NodePort

istioDisableInjectionOnObject ambassador default deployment

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/ambassador.yaml?$(date +%s)"  | kubectl apply -f -
kubectl apply -f /vagrant/yml/ambassador.yaml

kubectl patch svc ambassador-admin --type=json -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'
kubectl patch svc ambassador       --type=json -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30888}]'


#for load balancer
#export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export INGRESS_NODEPORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo INGRESS_HOST $INGRESS_HOST
echo INGRESS_PORT $INGRESS_PORT
echo INGRESS_NODEPORT $INGRESS_NODEPORT
echo GATEWAY_URL $GATEWAY_URL

#curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
curl http://${GATEWAY_URL}/springbootweb

}

createVistio()
{
git clone https://github.com/nmnellis/vistio.git
#set prometheus url
sed -i -e 's/prometheusURL: http:\/\/prometheus.istio-system:9090/prometheusURL: http:\/\/prometheus-cs.default.svc.cluster.local:9090/g' vistio/helm/vistio/values-mesh-only.yaml
cd vistio

#removed storageclass
cp /vagrant/conf/vistio/statefulset.yaml helm/vistio/templates/statefulset.yaml

helm install helm/vistio --name vistio --namespace default -f helm/vistio/values-mesh-only.yaml --set web.env.updateURL=http://vistio-api:30080/graph

#helm install helm/vistio --name vistio --namespace default -f helm/vistio/values-with-ingress.yaml
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/vistio.yaml?$(date +%s)"  | kubectl apply -f -
kubectl apply -f /vagrant/yml/vistio.yaml

cd ~
}

setupIstio()
{
curl -L https://git.io/getLatestIstio | sh -

ISTIO_VERSION=$(ls -l | grep istio- | cut -d ' ' -f 10)
ISTIO_VERSION=$(ls | grep istio- )

echo "ISTIO_VERSION $ISTIO_VERSION"

cd $ISTIO_VERSION
#Add the istioctl client to your PATH environment variable,
#export PATH=$PWD/bin:$PATH
#Install Istio’s Custom Resource Definitions via
#kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml

#before clean
#kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
#helm del --purge istio

#helm install install/kubernetes/helm/istio --name istio --namespace istio-system  -f install/kubernetes/helm/istio/values-istio-galley.yaml
#helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set global.proxy.includeIPRanges="10.32.0.0/12"
#helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set gateways.istio-ingressgateway.type=ClusterIP
#kubectl apply -f install/kubernetes/istio-demo-auth.yaml

sed -i -e "s/  type: LoadBalancer/  type: NodePort/g" install/kubernetes/istio-demo.yaml
kubectl apply -f install/kubernetes/istio-demo.yaml

#install citadel
kubectl apply -f install/kubernetes/istio-citadel-with-health-check.yaml

kubectl apply -f /vagrant/yml/citadel.yaml

istioEnableInjection apps

#set istio-ingressgateway nodeport to 30999
kubectl patch svc istio-ingressgateway -n istio-system --type=json -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30999}]'

kubectl get svc -n istio-system
kubectl get po -n istio-system

getPodIP istio-sidecar-injector- istio-system

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/istio.yaml?$(date +%s)"  | kubectl apply -f -
kubectl apply -f /vagrant/yml/istio.yaml

#install example
#curl https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml | kubectl apply -f -
#curl https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/bookinfo-gateway.yaml | kubectl apply -f -

#delete grafana and prometheus

kubectl delete svc -n istio-system grafana
kubectl delete svc -n istio-system prometheus
kubectl delete svc -n istio-system istio-galley
kubectl delete deployment -n istio-system grafana
kubectl delete deployment -n istio-system prometheus
# poniższe usuwam, bo z nim nie mogę zdefiniować VirtualService zawierające host z portem
kubectl delete deployment -n istio-system istio-galley



bin/istioctl proxy-config endpoint -n apps springbootmicroservice-0
bin/istioctl proxy-config listener -n apps springbootmicroservice-0
bin/istioctl proxy-config route -n apps springbootmicroservice-0
bin/istioctl proxy-config cluster -n apps springbootmicroservice-0
bin/istioctl proxy-config bootstrap -n apps springbootmicroservice-0
bin/istioctl proxy-config route -n apps springbootmicroservice-0
bin/istioctl proxy-status
 
}

createOpenFaasFunction()
{

functionName=hello-java8func
functionNamespace=openfaas-fn

export FAASGATEWAYIP=$(kubectl get svc --namespace openfaas gateway -o jsonpath='{.spec.clusterIP}')
echo FAASGATEWAYIP=$FAASGATEWAYIP

#CREATE FUNCTION
faas-cli new --lang java8 $functionName --prefix=marcinkasinski

sed -i -e 's/gateway: http:\/\/127.0.0.1/'"gateway: http:\/\/$FAASGATEWAYIP"'/g' $functionName.yml
#sed -i -e "s/image: $functionName:latest/image: marcinkasinski\/$functionName:latest/g" $functionName.yml

cat $functionName.yml

cp /vagrant/conf/openfaas/Handler.java $functionName/src/main/java/com/openfaas/function/Handler.java

#build 
faas-cli build -f ./$functionName.yml
 
#push
#docker login
faas-cli push -f ./$functionName.yml
#deploy
faas-cli deploy -f ./$functionName.yml
#URL: http://10.98.78.32:8080/function/hello-java8unc

kubectl -n $functionNamespace get functions

curl -XPOST --data "Marcin" -H "Content-Type:text/plain" http://$FAASGATEWAYIP:8080/function/$functionName

curl http://$FAASGATEWAYIP:8080/metrics | grep java

kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/$functionNamespace/pods/*/gateway_functions_seconds_count" | jq '.items[].value'
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/$functionNamespace/pods/*/gateway_functions_seconds_sum" | jq '.items[].value'

kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/$functionNamespace/pods/*/gateway_service_count" | jq '.items[].value'

kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_max" | jq '.items[].value'

kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/MKWEB_exec_time_seconds_avg" | jq '.items[].value'

curl http://10.44.0.10:8080/metrics | grep java
curl http://localhost:8080/apis/custom.metrics.k8s.io/v1beta1 | grep java


#for i in {1..50} ;do curl -XPOST --data "Marcin" -H "Content-Type:text/plain" http://$FAASGATEWAYIP:8080/function/$functionName &;   sleep 0.1 ;done

}

createOpenFaas()
{
functionNamespace=openfaas-fn

kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

istioDisableInjection openfaas
istioDisableInjection openfaas-fn

helm repo add openfaas https://openfaas.github.io/faas-netes/

#    functionNamespace has to be in the same namespace because of hpa

helm upgrade openfaas --install openfaas/openfaas \
    --namespace openfaas  \
    --set functionNamespace=$functionNamespace \
    --set serviceType=NodePort \
    --set basic_auth=false \
    --set operator.create=true

#install cli
sudo curl -sL https://cli.openfaas.com | sudo sh

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/openfaas.yaml?$(date +%s)"  | kubectl apply -f -

#kubectl patch deployment -n openfaas gateway -p='[{"op": "add", "path": "/metadata/labels", "value": "xx=xxxxx"}]'

kubectl patch deployment -n openfaas gateway  -p "$(cat /vagrant/conf/openfaas/gateway.patch)"

kubectl delete svc -n openfaas prometheus
kubectl delete svc -n openfaas alertmanager

kubectl delete deployment -n openfaas prometheus
kubectl delete deployment -n openfaas alertmanager

}

createKubeless()
{
export RELEASE=$(curl -s https://api.github.com/repos/kubeless/kubeless/releases/latest | grep tag_name | cut -d '"' -f 4)

kubectl create ns kubeless
kubectl create -f https://github.com/kubeless/kubeless/releases/download/$RELEASE/kubeless-$RELEASE.yaml

kubectl get pods -n kubeless
kubectl get deployment -n kubeless
kubectl get customresourcedefinition

#install cli

sudo apt install -y unzip
export OS=$(uname -s| tr '[:upper:]' '[:lower:]')

curl -OL https://github.com/kubeless/kubeless/releases/download/$RELEASE/kubeless_$OS-amd64.zip && \
unzip kubeless_$OS-amd64.zip && \
sudo mv bundles/kubeless_$OS-amd64/kubeless /usr/local/bin/

kubeless function ls

kubectl get pods -l function=hellomkfunction
 
#deploy function

#kubeless function deploy foo --from-file HelloGet.java --handler hello.foo --runtime java1.8

#kubeless function deploy hello --runtime python2.7 \
#                                --from-file test.py \
#                                --handler test.hello
 
kubectl apply -f https://raw.githubusercontent.com/kubeless/kubeless-ui/master/k8s.yaml
}

installfnApp()
{

APP=appmktxt2

kubectl get svc --namespace default fm-release-fn-api
#export FN_API_URL=http://$(kubectl get svc --namespace default fm-release-fn-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):80
export FN_API_URL=http://$(kubectl get svc --namespace default fm-release-fn-api -o jsonpath='{.spec.clusterIP}'):80
echo $FN_API_URL


#https://fnproject.io/tutorials/JavaFDKIntroduction/
#firstfunction

echo "fn initializing"

fn init --runtime java --trigger http $APP
cd $APP
cat func.yaml
export FN_REGISTRY=marcinkasinski
docker login

echo "fn building"

fn --verbose build
fn --verbose deploy --registry marcinkasinski --app $APP
fn list triggers #APP


#Updating function appmktxt using image marcinkasinski/appmktxt:0.0.2...
#Successfully created app:  appmktxt
#Successfully created function: appmktxt with marcinkasinski/appmktxt:0.0.2
#Successfully created trigger: appmktxt-trigger
#Trigger Endpoint: http://10.98.153.28:80/t/appmktxt/appmktxt-trigger


curl http://10.98.153.28:80/t/appmktxt/appmktxt-trigger

}

createfnproject()
{

kubectl create clusterrolebinding fnproject --clusterrole=cluster-admin --serviceaccount kube-system:default

git clone https://github.com/fnproject/fn-helm.git
cd fn-helm
#Install chart dependencies (from requirements.yaml):
helm dep build fn

#Then install the chart. I chose the release name fm-release:
echo "Installing fn"

helm install --name fm-release fn
#patch ui service

echo "patching fn"

kubectl patch svc fm-release-fn-ui --type=json -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'
kubectl patch svc fm-release-fn-api --type=json -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'

echo "kubectl fn"

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fnproject.yaml?$(date +%s)"  | kubectl apply -f -

echo "Install fn on local nachine"

# install fn on local nachine
sudo curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh
#wget https://raw.githubusercontent.com/fnproject/cli/master/install | sh
#chmod u+x install
#./install

fn version

fn list contexts

}



remove_LVM_logical_volume(){

#list partitions
lsblk

#delete sdc disk
sudo dd if=/dev/zero of=/dev/sdc bs=512 count=1

#vagrant plugin creates logical volume.

#We have to remove it
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL
sudo lvmdiskscan
sudo lvscan
#umount /dev/MKmyvolgroup/vps
sudo lvremove -f /dev/MKmyvolgroup/vps
sudo lvscan
}

installHelm()
{
#wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-rc.1-linux-arm64.tar.gz

#tar -xvzf helm-v2.12.0-rc.1-linux-arm64.tar.gz

#sudo snap install helm --classic

#install from script
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

#sudo -H -u vagrant bash -c 'helm init' 
helm init
helm repo update

getPodIP tiller-deploy- kube-system
IP_TILLER=$retval
waitForIPPort $IP_TILLER 44134 
}

setupJava()
{
sudo apt install -y openjdk-9-jre-headless

java -version
}

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
local NAMESPACE=$2

echo createServerCert $host $NAMESPACE


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

kubectl delete configmap keystore-$shorthostname.jks -n $NAMESPACE | true
kubectl delete configmap truststore-$shorthostname.jks -n $NAMESPACE | true

kubectl create configmap keystore-$shorthostname.jks -n $NAMESPACE --from-file=/tmp/keystore-$shorthostname.jks
kubectl create configmap truststore-$shorthostname.jks -n $NAMESPACE --from-file=/tmp/truststore-$shorthostname.jks

}


setupSSL()
{
local NAMESPACE=$1

echo setupSSL $NAMESPACE
sudo rm /tmp/key* && sudo rm /tmp/tr* && sudo rm /tmp/ce* && sudo rm /tmp/ca*

createCA
# kafka certs in default namespace
createServerCert kafka-0.k-hs.default.svc.cluster.local default
createServerCert kafka-1.k-hs.default.svc.cluster.local default
createServerCert kafka-2.k-hs.default.svc.cluster.local default
createServerCert springbootweb-0.springbootweb-hs.$NAMESPACE.svc.cluster.local $NAMESPACE
createServerCert springbootkafkalistener-0.springbootkafkalistener-hs.$NAMESPACE.svc.cluster.local $NAMESPACE
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

createWeave()
{
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

#weave scope
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/weave.yaml?$(date +%s)"  | kubectl apply -n weave -f -

}


init_kubernetes()
{
#sudo rm -rf ~/.kube && sudo kubeadm reset && 

# for ubuntu 16
#IP=$( ifconfig enp0s8 | grep "inet " | cut -d: -f2 | awk '{ print $1}' )

# for ubuntu 18
IP=$(ifconfig enp0s8 | sed -n '/inet /s/.*inet  *\([^[:space:]]\+\).*/\1/p' )

echo  "IP $IP"

#sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP  --kubernetes-version stable-1.11 --ignore-preflight-errors all|  grep "kubeadm join"  >join_command


#sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP |  grep "kubeadm join"  >join_command
#--------
#sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address $IP  >kubeadm_join

#for weave networking
sudo kubeadm init --pod-network-cidr 10.32.0.0/12 --apiserver-advertise-address $IP  2>&1 | tee kubeadm_join

#sudo kubeadm init --apiserver-advertise-address $IP --kubernetes-version stable-1.12  2>&1 | tee kubeadm_join

cat kubeadm_join
cat kubeadm_join |  grep "kubeadm join"  >join_command


JOIN_COMMAND="$( cat join_command )"

echo "sudo $JOIN_COMMAND" > join_command_sudo

cat join_command_sudo



sudo apt install -y nginx
sudo -H -u root bash -c 'cat join_command_sudo > /var/www/html/join_command_sudo' 

echo "curl k8smaster/join_command_sudo"	

curl k8smaster/join_command_sudo

#--------

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>CREATING CONF "

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

#taint pods on master nodes
kubectl taint nodes --all node-role.kubernetes.io/master-

#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

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

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10-release/src/deploy/recommended/kubernetes-dashboard.yaml
#add defalt to admin
kubectl create clusterrolebinding defaultdminrolebinding --clusterrole=cluster-admin --serviceaccount kube-system:default

kubectl create clusterrolebinding kubernetes-dashboard-rolebinding --clusterrole=cluster-admin --serviceaccount kube-system:kubernetes-dashboard

kubectl create namespace apps

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

service nfs-kernel-server status
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

echo "getPodIP"
local POD_NAME=$1
local POD_NAMESPACE=$2
local POD_LABEL=$3

  echo "name $POD_NAME"

OPTS="";

if [ ! -z "$POD_NAMESPACE" ]; then 
  #there is POD_NAMESPACE
  OPTS=" -n $POD_NAMESPACE ";
  echo "namespace $POD_NAMESPACE"
fi

if [ ! -z "$POD_LABEL" ]; then 
  #there is POD_LABEL
  OPTS=$OPTS" -l $POD_LABEL ";
  echo "label $POD_LABEL "
fi

echo "OPTS [$OPTS]" 

while ! kubectl get po $OPTS -o wide | grep $POD_NAME | grep Running ; do   echo "waiting for pod $POD_NAME IP ..." ; sleep 20 ; done

PODIP=`kubectl get po $OPTS -o wide | grep $POD_NAME | grep Running `
PODIP=`echo $PODIP | cut -d " " -f 6`
#echo $PODIP
retval=$PODIP
}

waitForPVC()
{

echo "waitForPVC"
local PVC_NAME=$1
local PVC_NAMESPACE=$2

OPTS="";

if [ ! -z "$PVC_NAMESPACE" ]; then 
  #there is PVC_NAMESPACE
  OPTS=" -n $PVC_NAMESPACE ";
  echo "namespace $PVC_NAMESPACE "
fi

echo "OPTS [$OPTS]" 

while ! kubectl get pvc $OPTS | grep $PVC_NAME | grep Bound ; do   echo "waiting for pod $PVC_NAME IP ..." ; sleep 20 ; done

PODIP=`kubectl get pvc $OPTS | grep $PVC_NAME | grep Bound `
PODIP=`echo $PODIP | cut -d " " -f 6`
#echo $PODIP
retval=$PODIP
}


waitForIPPort()
{
local IP=$1
local PORT=$2

echo "waitForIPPort IP $IP, PORT $PORT"

while true
do
  nc -z $IP $PORT
  sleep 3  

  if [ $? != 0 ]; then
     echo  "nc Error "
     #exit $ERROR_CODE
  else break   
  fi
done
}

waitForPODPort()
{
local POD_NAME=$1
local PORT=$2
local NAMESPACE=$3

echo "waitForPODPort POD_NAME $POD_NAME, PORT $PORT"

while true
do
  #IP=$(getPodIP $POD_NAME)
  getPodIP $POD_NAME $NAMESPACE
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

waitForIPPort $IP_0 6379
waitForIPPort $IP_1 6379
waitForIPPort $IP_2 6379
waitForIPPort $IP_3 6379
waitForIPPort $IP_4 6379
waitForIPPort $IP_5 6379

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
 
#while ! kubectl get po -o wide | grep kafka-0 | grep Running ; do   echo "waiting for kafka IP..." ; sleep 20 ; done

getPodIP kafka-0 default
getPodIP kafka-1 default
getPodIP kafka-2 default

KAFKAPODIP=`kubectl get po -o wide | grep kafka-0 | grep Running `
echo $KAFKAPODIP
KAFKAPODIP=`echo $KAFKAPODIP  | cut -d " " -f 6`
echo $KAFKAPODIP

while ! nc -z $KAFKAPODIP 9092; do   echo "waiting kafka to launch ..." ; sleep 20 ; done

#cd /tmp
#curl http://ftp.ps.pl/pub/apache/kafka/1.0.0/kafka_2.11-1.0.0.tgz | tar xvz
#/tmp/kafka_2.11-1.0.0/bin/kafka-topics.sh --list --zookeeper $KAFKAPODIP:2181

zookeeper=zk-0.zk-hs.default.svc.cluster.local:2181,zk-1.zk-hs.default.svc.cluster.local:2181,zk-2.zk-hs.default.svc.cluster.local:2181/kafka

kubectl exec kafka-0 -- bash -c "KAFKA_OPTS="" /opt/kafka/bin/kafka-topics.sh --create --zookeeper $zookeeper --partitions 6 --replication-factor 3 --topic fluentd-springboot-logs"
kubectl exec kafka-0 -- bash -c "KAFKA_OPTS="" /opt/kafka/bin/kafka-topics.sh --create --zookeeper $zookeeper --partitions 6 --replication-factor 3 --topic fluentd-kubernetes-logs"
kubectl exec kafka-0 -- bash -c "KAFKA_OPTS="" /opt/kafka/bin/kafka-topics.sh --create --zookeeper $zookeeper --partitions 6 --replication-factor 3 --topic my-topic"

setKafkaClusterACL "CN=kafka-0.k-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "kafka-cluster" "--operation ClusterAction"
setKafkaClusterACL "CN=kafka-1.k-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "kafka-cluster" "--operation ClusterAction"
setKafkaClusterACL "CN=kafka-2.k-hs.default.svc.cluster.local,OU=it,O=itzone,C=PL" "kafka-cluster" "--operation ClusterAction"

setKafkaTopicACL "CN=springbootkafkalistener-0.springbootkafkalistener-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL" "my-topic" "--operation Create --operation Describe --operation Read"
setKafkaGroupACL "CN=springbootkafkalistener-0.springbootkafkalistener-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL" "order" "--operation Describe --operation Read"
setKafkaTopicACL "CN=springbootkafkalistener-0.springbootkafkalistener-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL" "__consumer_offsets" "--operation Describe"


setKafkaClusterACL "ANONYMOUS" "kafka-cluster" "--operation Create"

setKafkaTopicACL "ANONYMOUS" "__consumer_offsets" "--operation Describe"
setKafkaGroupACL "ANONYMOUS" "group1" "--operation Describe --operation Read"
setKafkaGroupACL "ANONYMOUS" "fluent_group" "--operation Describe --operation Read"
setKafkaGroupACL "ANONYMOUS" "glogstashelk" "--operation Describe --operation Read"
#setKafkaTopicACL "ANONYMOUS" "my-topic" "--operation Describe" # nie mam pojecia czemu te uprawnienie jest potrzebnez weba
setKafkaTopicACL "ANONYMOUS" "logs" "--operation Create --operation Describe --operation Read --operation Write"
setKafkaTopicACL "ANONYMOUS" "fluentd-springboot-logs" "--operation Create --operation Describe --operation Read --operation Write"
setKafkaTopicACL "ANONYMOUS" "fluentd-kubernetes-logs" "--operation Create --operation Describe --operation Read --operation Write"

setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL "my-topic" "--operation Describe --operation Create --operation Write"
setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL "__consumer_offsets" "--operation Describe"
#setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL "logs" "--operation Describe --operation Create --operation Write"
#setKafkaTopicACL CN=springbootweb-0.springbootweb-hs.apps.svc.cluster.local,OU=it,O=itzone,C=PL "fluentd-logs" "--operation Describe --operation Create --operation Write"

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

#create folder
DASHBOARD="{  \"uid\": \"istio\",  \"title\": \"Istio Dashboards\"}"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/folders

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

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_mesh.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_service.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_workload.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_mixer.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_pilot.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_performance.json) }"
curl -XPOST --data "$DASHBOARD" -H "Content-Type:application/json"  http://admin:admin@$GRAFANAPODIP:3000/api/dashboards/db

DASHBOARD="{\"dashboard\":  $(</vagrant/conf/grafana/grafana_dashboard_istio_galley.json) }"
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

#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/grafana.yaml?$(date +%s)"  | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/prometheus.yaml?$(date +%s)"   | sed -e 's/  replicas: 1/  replicas: 1/g' | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/alertmanager.yaml?$(date +%s)" | sed -e 's/  replicas: 1/  replicas: 3/g' | kubectl apply -f -

echo createMonitoring grafana
kubectl apply -f /vagrant/yml/grafana.yaml
echo createMonitoring prometheus
kubectl apply -f /vagrant/yml/prometheus.yaml
cat /vagrant/yml/alertmanager.yaml | sed -e 's/  replicas: 1/  replicas: 3/g' | kubectl apply -f -

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

#kubectl apply -f /vagrant/yml/monitoring/namespaces.yaml

#kubectl create configmap key -n custom-metrics --from-file=/vagrant/conf/certs/prometheusadapter.key
#kubectl create configmap crt -n custom-metrics --from-file=/vagrant/conf/certs/prometheusadapter.crt

#kubectl apply -f /vagrant/yml/monitoring/manifests

helm install --name prometheus-adapter stable/prometheus-adapter --namespace=prometheus-adapter -f /vagrant/conf/prometheus_adapter/prometheus_adapter-overrides.yaml

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
#set 4 replicas
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml | sed -e 's/  replicas: 1/  replicas: 4/g' | kubectl apply -f -
curl "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml?$(date +%s)"  | kubectl apply -f -

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


createMyBackendServers()
{
#curl http://es:9200/_cluster/health
#curl http://es:9200/_cat/indices?v
#curl http://es:9200/_nodes
#curl http://es:9200/_cluster/stats?human&pretty


curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elasticsearch.yaml?$(date +%s)" | kubectl apply -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/elastic-exporter.yaml?$(date +%s)" | kubectl apply -f -
#curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/logstash.yaml?$(date +%s)" | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/kibana.yaml?$(date +%s)" | kubectl apply -f -

curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/jenkins.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/artifactory.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/rabbitmq.yaml | kubectl apply -f -
}

createMyapps()
{
# moje aplikacje

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/phpmyadmin_dp_and_service.yaml?$(date +%s)"  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/nginx.yaml?$(date +%s)"  | kubectl apply -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/zipkin.yaml?$(date +%s)"  | kubectl apply -n apps -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootrabbitmqListener.yaml?$(date +%s)"  | kubectl apply -n apps -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootkafkalistener.yaml?$(date +%s)"  | kubectl apply -n apps -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootsoapservice.yaml?$(date +%s)"  | kubectl apply -n apps -f -

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootmicroservice.yaml?$(date +%s)"  | kubectl apply -n apps -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootmicroservice-v2.yaml?$(date +%s)"  | kubectl apply -n apps -f -
curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/springbootweb.yaml?$(date +%s)"  | kubectl apply -n apps -f -

}

getConfFromCephServer()
{

#get ceph conf from ceph server
scp -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key_cephuser cephuser@cephadmin:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key_cephuser cephuser@cephadmin:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring
scp -o "StrictHostKeyChecking=no" -i /home/vagrant/.ssh/private_key_cephuser cephuser@cephadmin:/home/cephuser/cluster/ceph.client.kube.keyring /etc/ceph/ceph.client.kube.keyring
}

createCephRook()
{
helm repo add rook-master https://charts.rook.io/master

helm search rook
helm repo update

# Create a ServiceAccount for Tiller in the `kube-system` namespace
kubectl --namespace kube-system create sa tiller

# Create a ClusterRoleBinding for Tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

# Patch Tiller's Deployment to use the new ServiceAccount
kubectl --namespace kube-system patch deploy/tiller-deploy -p '{"spec": {"template": {"spec": {"serviceAccountName": "tiller"}}}}'


helm install --name rook rook-master/rook --namespace kube-system --version v0.7.0-136.gd13bc83 --set rbacEnable=true

}

createcephObjects()
{

OSD_POD1_NAME=$(kubectl get po -n ceph -l component=osd -o jsonpath="{.items[0].metadata.name}")
OSD_POD2_NAME=$(kubectl get po -n ceph -l component=osd -o jsonpath="{.items[1].metadata.name}")
OSD_POD3_NAME=$(kubectl get po -n ceph -l component=osd -o jsonpath="{.items[2].metadata.name}")

echo OSD_POD1_NAME $OSD_POD1_NAME
echo OSD_POD2_NAME $OSD_POD2_NAME
echo OSD_POD3_NAME $OSD_POD3_NAME

getPodIP ceph-mon ceph "application=ceph,component=mon"

getPodIP $OSD_POD1_NAME ceph "application=ceph,component=osd"
getPodIP $OSD_POD2_NAME ceph "application=ceph,component=osd"
getPodIP $OSD_POD3_NAME ceph "application=ceph,component=osd"

OSD_NUMBER_READY=$(kubectl get daemonset -n ceph -l component=osd -o jsonpath="{.items[0].status.numberReady}")

echo OSD_NUMBER_READY $OSD_NUMBER_READY

echo "OSD_POD1_NAME $OSD_POD1_NAME";
echo "OSD_POD2_NAME $OSD_POD2_NAME";
echo "OSD_POD3_NAME $OSD_POD3_NAME";
echo "OSD_STATUS $OSD_STATUS";

CEPH_MON_POD=$(kubectl get pod -l component=mon,application=ceph -n ceph -o jsonpath="{.items[0].metadata.name}")
echo CEPH_MON_POD $CEPH_MON_POD
kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- ceph -s

echo Create a keyring for the k8s user
#kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- ceph auth get-or-create-key client.k8s mon 'allow r' osd 'allow rwx pool=rbd'  | base64


CEPH_MON_SECRET=$(kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- ceph auth get-or-create-key client.k8s mon 'allow r' osd 'allow rwx pool=rbd'  | base64)
echo CEPH_MON_SECRET $CEPH_MON_SECRET

#echo key=$CEPH_MON_SECRET > keyring.txt

#kubectl create secret generic -n ceph pvc-ceph-client-key --from-file=keyring.txt

kubectl -n ceph get secrets/pvc-ceph-client-key -o yaml >keyring.yaml


sed -i -e "s/  key: \"\"/  key: $CEPH_MON_SECRET/g" keyring.yaml

kubectl apply -n ceph -f keyring.yaml

kubectl -n ceph get secrets

# create secret in default for client

kubectl -n ceph get secrets/pvc-ceph-client-key -o json | jq '.metadata.namespace = "default"' | kubectl create -f -

#Create and initialize the RBD pool
#Original produces error: 
#Error ERANGE:  pg_num 256 size 3 would mean 912 total pgs, which exceeds max 600 (mon_max_pg_per_osd 200 * num_in_osds 3)

#kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- ceph osd pool create rbd 256
#changet to
kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- ceph osd pool create rbd 128
kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- rbd pool init rbd

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/ceph_pvc.yaml?$(date +%s)"  | kubectl apply -f -

#check that the RBD has been created on your cluster
#kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- rbd ls

CEPH_RBD=$(kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- rbd ls)
echo $CEPH_RBD

kubectl -n ceph exec -ti $CEPH_MON_POD -c ceph-mon -- rbd info $CEPH_RBD

kubectl get pvc
waitForPVC ceph-pvc

}

createceph()
{

echo "createceph"
cd /root/

nohup helm serve &

sleep 1

while ! nc -z localhost 8879; do   echo "waiting for local charts ..." ; sleep 5 ; done

sleep 1

helm repo add local http://localhost:8879/charts

git clone https://github.com/ceph/ceph-helm

cd ceph-helm/ceph
sudo apt install -y make

make

cp /vagrant/conf/ceph/ceph-overrides.yaml ~/ceph-overrides.yaml

kubectl create namespace ceph

kubectl create -f ~/ceph-helm/ceph/rbac.yaml

kubectl label node k8smaster ceph-mon=enabled ceph-mgr=enabled ceph-mds=enabled ceph-rgw=enabled --overwrite

kubectl label node k8snode1 ceph-osd=enabled ceph-osd-device-dev-sdc=enabled ceph-rgw=enabled --overwrite
kubectl label node k8snode2 ceph-osd=enabled ceph-osd-device-dev-sdc=enabled ceph-rgw=enabled --overwrite
kubectl label node k8snode3 ceph-osd=enabled ceph-osd-device-dev-sdc=enabled ceph-rgw=enabled--overwrite

echo "Helm installing ceph"

helm install --name=ceph local/ceph --namespace=ceph -f ~/ceph-overrides.yaml

#kubectl logs -f -n ceph ceph-osd-dev-sdc-ms5ml -c osd-prepare-pod



echo "createceph end"
}
