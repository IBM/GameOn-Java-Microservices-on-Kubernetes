#!/bin/sh

function install_bluemix_cli() {
#statements
echo "Installing Bluemix cli"
curl -L "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar -zx
sudo mv cf /usr/local/bin
sudo curl -o /usr/share/bash-completion/completions/cf https://raw.githubusercontent.com/cloudfoundry/cli/master/ci/installers/completion/cf
cf --version
curl -L public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.1_amd64.tar.gz > Bluemix_CLI.tar.gz
tar -xvf Bluemix_CLI.tar.gz
sudo ./Bluemix_CLI/install_bluemix_cli
}

function install_kubectl() {
bx plugin install container-service -r Bluemix
echo "Installing kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
}

function cluster_setup() {
bx cs workers $CLUSTER_NAME
$(bx cs cluster-config $CLUSTER_NAME | grep export)
kubectl delete --ignore-not-found=true -f gameon-configmap.yaml
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
}

function initial_setup() {
IP=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{print $2}' | head -1)
kubectl create -f local-volume.yaml
sleep 5s
sed -i s#PLACEHOLDER_IP#$IP#g gameon-configmap.yaml
kubectl create -f gameon-configmap.yaml
kubectl create -f setup.yaml
echo "Waiting for container to setup"
sleep 45

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
    if [ $TRIES -eq 40 ]
    then
        echo "Failed setting up keystore values."
        exit 1
    fi
    TRIES=$((TRIES+1))
    sleep 5s
done
}

function create_platform_services() {
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
IP=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{print $2}' | head -1)
TRIES=0
while true
do
code=$(curl -sw '%{http_code}' http://$IP:31200/health -o /dev/null)
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
IP=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{print $2}' | head -1)
TRIES=0
while true
do
code=$(curl -sw '%{http_code}' http://$IP:31300/uptime -o /dev/null)
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
}

function create_core_services() {

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
        kubectl logs $(kubectl get pods | grep proxy | awk '{print $1}') | grep UP
        echo "Everything seems to be working fine!"
        echo "Travis build has finished. Cleaning up..."
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
}




install_bluemix_cli
install_kubectl
cluster_setup
initial_setup
create_platform_services
create_core_services
cluster_setup
