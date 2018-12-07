createfnproject()
{

##DEFAULT AS WARNING
kubectl create clusterrolebinding fnproject --clusterrole=cluster-admin --serviceaccount kube-system:default

git clone https://github.com/fnproject/fn-helm.git
cd fn-helm
#Install chart dependencies (from requirements.yaml):
helm dep build fn

#Then install the chart. I chose the release name fm-release:
helm install --name fm-release fn
#patch ui service

kubectl patch svc fm-release-fn-ui --type=json -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'
kubectl patch svc fm-release-fn-api --type=json -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fnproject.yaml?$(date +%s)"  | kubectl apply -f -

kubectl get svc --namespace default fm-release-fn-api
#export FN_API_URL=http://$(kubectl get svc --namespace default fm-release-fn-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):80
export FN_API_URL=http://$(kubectl get svc --namespace default fm-release-fn-api -o jsonpath='{.spec.clusterIP}'):80
echo $FN_API_URL


# install fn on local nachine
curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh


fn version

fn list contexts

#https://fnproject.io/tutorials/JavaFDKIntroduction/
#firstfunction
fn init --runtime java --trigger http javafnmktst
cd javafnmktst
cat func.yaml
export FN_REGISTRY=marcinkasinski
#docker login
fn --verbose build
#fn --verbose deploy --registry marcinkasinski --app java-app
#fn list triggers java-app
}




createfnproject