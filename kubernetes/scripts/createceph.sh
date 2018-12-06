helm serve &
helm repo add local http://localhost:8879/charts

git clone https://github.com/ceph/ceph-helm

cd ceph-helm/ceph
sudo apt install -y make

make

cp /vagrant/conf/ceph/ceph-overrides.yaml /home/vagrant/ceph-overrides.yaml

kubectl create namespace ceph

kubectl create -f ~/ceph-helm/ceph/rbac.yaml


kubectl label node k8smaster ceph-mon=enabled ceph-mgr=enabled ceph-mds=enabled  --overwrite

kubectl label node k8snode1 ceph-osd=enabled ceph-osd-device-dev-sdc=enabled --overwrite
kubectl label node k8snode2 ceph-osd=enabled ceph-osd-device-dev-sdc=enabled --overwrite
kubectl label node k8snode3 ceph-osd=enabled ceph-osd-device-dev-sdc=enabled --overwrite

helm install --name=ceph local/ceph --namespace=ceph -f ~/ceph-overrides.yaml


#kubectl -n ceph exec -ti ceph-mon-q7t9l -c ceph-mon -- ceph -s

#kubectl logs -f -n ceph ceph-osd-dev-sdc-ms5ml -c osd-prepare-pod