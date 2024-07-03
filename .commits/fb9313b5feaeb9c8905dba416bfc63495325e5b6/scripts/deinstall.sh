#!/bin/bash

using_kubernetes=true

if [ "$using_kubernetes" = true ]; then
  kubectl delete service docker-registry-ui --grace-period=0 --force
  kubectl delete service docker-registry --grace-period=0 --force
  kubectl delete deployment docker-registry --grace-period=0 --force
  kubectl delete deployment docker-registry-ui --grace-period=0 --force
  kubectl delete pvc docker-registry-data-pv-claim --grace-period=0 --force
  kubectl delete pvc docker-registry-auth-pv-claim --grace-period=0 --force
  kubectl delete pv docker-registry-data-pv --grace-period=0 --force
  kubectl delete pv docker-registry-auth-pv --grace-period=0 --force
else
  sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=registry:2.7 --format="{{.ID}}"))
  sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=konradkleine/docker-registry-frontend:v2 --format="{{.ID}}"))
fi

sudo rm -r ~/docker-registry
