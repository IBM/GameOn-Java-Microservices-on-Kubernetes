#!/bin/bash
kubectl get nodes
IP_ADDR=$(kubectl get nodes | grep Ready | awk '{print $1}' | head -1)

if [ -z "$IP_ADDR" ]
then
    echo "IP Address not found"
    exit 1
fi

for filename in core/*.yaml
do
    sed -i '' s#169\.47\.241\.213#$IP_ADDR# $filename
done

sed -i '' s#169\.47\.241\.213#$IP_ADDR# setup.yaml
