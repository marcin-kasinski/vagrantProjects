#!/bin/bash
# set -o xtrace


kubelogs(){

SEARCH=$1

PODNAME=`kubectl get po | grep $SEARCH| grep Running | cut -d " " -f 1`

echo $PODNAME

kubectl logs -f $PODNAME 

}


kubeexec(){

SEARCH=$1
echo "Searching $SEARCH"

PODNAME=`kubectl get po | grep $SEARCH| grep Running | cut -d " " -f 1`

echo "Pod name: $PODNAME"

kubectl exec -it $PODNAME -- /bin/bash -

}


COMMAND=$1
ARG=$2


echo $COMMAND


if [ "$COMMAND" = "e" ]
then
kubeexec $ARG
elif [ "$COMMAND" = "l" ]
then
kubelogs $ARG
fi

