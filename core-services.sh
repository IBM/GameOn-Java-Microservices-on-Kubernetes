#!/bin/bash
kubectl create -f core/auth.yaml
kubectl create -f core/map.yaml
kubectl create -f core/mediator.yaml
kubectl create -f core/player.yaml
kubectl create -f core/proxy.yaml
kubectl create -f core/room.yaml
kubectl create -f core/webapp.yaml
