#!/bin/bash

using_kubernetes=true

if [ "$using_kubernetes" = true ]; then
  kubectl delete service docker-registry-ui
  kubectl delete service docker-registry
  kubectl delete deployment docker-registry
  kubectl delete deployment docker-registry-ui
  kubectl delete pvc docker-registry-data-pv-claim
  kubectl delete pvc docker-registry-auth-pv-claim
  kubectl delete pv docker-registry-data-pv
  kubectl delete pv docker-registry-auth-pv
else
  sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=registry:2.7 --format="{{.ID}}"))
  sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=konradkleine/docker-registry-frontend:v2 --format="{{.ID}}"))
fi

sudo rm -r ~/docker-registry
