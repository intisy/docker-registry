#!/bin/bash

using_kubernetes=$3
using_ui=$4
using_docker_ui_test=$5

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}

if [ "$using_kubernetes" = true ]; then
  echo2 "Deleting Kubernetes Docker registry!"
  kubectl delete service docker-registry --grace-period=0 --force
  kubectl delete deployment docker-registry --grace-period=0 --force
  kubectl delete pods -l app=docker-registry --grace-period=0 --force
  kubectl delete pvc docker-registry-data-pv-claim --grace-period=0 --force
  kubectl delete pvc docker-registry-auth-pv-claim --grace-period=0 --force
  kubectl delete pv docker-registry-data-pv --grace-period=0 --force
  kubectl delete pv docker-registry-auth-pv --grace-period=0 --force
  if [ "$using_ui" = true ]; then
    if [ "$using_docker_ui_test" = true ]; then
      ui=true
    else
      echo2 "Deleting Kubernetes Docker registry ui!"
      kubectl delete service docker-registry-ui --grace-period=0 --force
      kubectl delete deployment docker-registry-ui --grace-period=0 --force
    fi
  fi
else
  echo2 "Deleting Docker registry!"
  sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=registry:2.7 --format="{{.ID}}"))
  echo2 "test1"
  if [ "$using_ui" = true ]; then
    echo2 "test"
    ui=true
  fi
fi
if [ "$ui" = true ]; then
  echo2 "Deleting Docker registry ui!"
  sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=konradkleine/docker-registry-frontend:v2 --format="{{.ID}}"))
fi

sudo rm -r ~/docker-registry
