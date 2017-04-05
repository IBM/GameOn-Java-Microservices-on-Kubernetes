#!/bin/bash
kubectl create -f platform/controller.yaml
kubectl create -f platform/couchdb.yaml
kubectl create -f platform/es.yaml
kubectl create -f platform/gateway.yaml
kubectl create -f platform/kafka.yaml
kubectl create -f platform/kibana.yaml
kubectl create -f platform/logstash.yaml
kubectl create -f platform/redis.yaml
kubectl create -f platform/registry.yaml