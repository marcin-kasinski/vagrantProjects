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

curl "https://raw.githubusercontent.com/marcin-kasinski/vagrantProjects/master/kubernetes/yml/fnproject.yaml?$(date +%s)"  | kubectl apply -f -

}




createfnproject