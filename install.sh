#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry --network registry \
  -v ./auth:/auth \
  -v $(pwd)/registry:/var/lib/registry \
  registry:2.7
sudo docker run --rm -it --name docker-registry-ui --network registry \
  -e ENV_DOCKER_REGISTRY_HOST=docker-registry \
  -e ENV_REGISTRY_PORT=5000 -p 8080:80 \
  konradkleine/docker-registry-frontend:v2
