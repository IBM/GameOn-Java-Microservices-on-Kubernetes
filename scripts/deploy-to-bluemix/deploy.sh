#!/bin/bash

echo "Creating GameOn App"

IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

kubectl delete pvc -l app=gameon
kubectl delete --ignore-not-found=true -f core
kubectl delete --ignore-not-found=true -f platform
kubectl delete --ignore-not-found=true -f setup.yaml
kuber=$(kubectl get pods -l app=gameon)
while [ ${#kuber} -ne 0 ]
do
    sleep 5s
    kubectl get pods -l app=gameon
    kuber=$(kubectl get pods -l app=gameon)
done
kubectl delete --ignore-not-found=true -f local-volume.yaml

echo -e "Creating local volumes"
kubectl create -f local-volume.yaml

sleep 5s
kubectl create -f setup.yaml
echo "Waiting for container to setup"
sleep 15s

keystore=$(kubectl logs setup | grep Import | awk '{print $4}')
TRIES=0
while [ "$keystore" != "104" ]
do
    echo "Setting up keystore values..."
    keystore=$(kubectl logs setup | grep Import | awk '{print $4}')
    if [ "$keystore" = "104" ]
    then
        echo "Setup successfull"
        break
    fi
    if [ $TRIES -eq 10 ]
    then
        echo "Failed setting up keystore values."
        exit 1
    fi
    TRIES=$((TRIES+1))
    sleep 5s
done

echo "Deploying Platform services..."
kubectl create -f platform

echo "Waiting for pods to setup"
sleep 10s
PODS=$(kubectl get pods | grep Pending)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are Pending..."
    PODS=$(kubectl get pods | grep Pending)
    sleep 5s
done

PODS=$(kubectl get pods | grep ContainerCreating)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are not yet Running..."
    PODS=$(kubectl get pods | grep ContainerCreating)
    sleep 5s
done

echo "Pods for the platform services are now Running."
echo "Waiting for the amalgam8 controlplane to finish setup..."

TRIES=0
while true
do
code=$(curl -w '%{http_code}' http://$IP_ADDR:31200/health -o /dev/null)
    if [ "$code" = "200" ]; then
        echo "Controller is up"
        break
    fi
    if [ $TRIES -eq 10 ]
    then
        echo "Failed setting up controlplane."
        exit 1
    fi
    TRIES=$((TRIES+1))
    sleep 5s
done

TRIES=0
while true
do
code=$(curl -w '%{http_code}' http://$IP_ADDR:31300/uptime -o /dev/null)
    if [ "$code" = "200" ]; then
        echo "Registry is up"
        break
    fi
    if [ $TRIES -eq 10 ]
    then
        echo "Failed setting up controlplane."
        exit 1
    fi
    TRIES=$((TRIES+1))
    sleep 5s
done

sed -i s#169.47.241.213#$IP_ADDR#g core/*

kubectl create -f core

echo "Waiting for pods to setup"
sleep 10s
PODS=$(kubectl get pods | grep Pending)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are Pending..."
    PODS=$(kubectl get pods | grep Pending)
    sleep 5s
done

PODS=$(kubectl get pods | grep ContainerCreating)
while [ ${#PODS} -ne 0 ]
do
    echo "Some Pods are not yet Running..."
    PODS=$(kubectl get pods | grep ContainerCreating)
    sleep 5s
done

echo "Pods for the core services are now Running."
echo "Waiting for core services to finish setting up..."
# kubectl logs $(kubectl get pods | grep proxy | awk '{print $1}') | tail -10

TRIES=0

while true
do
CORE=$(kubectl logs $(kubectl get pods | grep proxy | awk '{print $1}') | grep UP | awk '{print $8}' | xargs | sed -e s/,//g)

    if [ "$CORE" = "UP UP UP UP UP" ]
    then
        echo "You can now access your Gameon App at https://$IP_ADDR:30443"
        echo "If you'd like to add social logins, please follow the instructions in the Repository's README"
        break
    fi

    if [ $TRIES -eq 60 ]
    then
        echo "Failed to setup core services."
        echo "Printing running services detected by proxy:"
        kubectl logs $(kubectl get pods | grep proxy | awk '{print $1}') | grep UP | awk '{print $6}'
        exit 1
    fi
    echo "Waiting for core services to finish setting up..."
    sleep 10s
done
