#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
# cd auth
# sudo apt install apache2-utils -y
# sudo htpasswd -b -c auth.htpasswd root root
# cd ..
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry --network registry \
  # -e REGISTRY_AUTH=htpasswd \
  # -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/auth.htpasswd \
  -v ./auth:/auth \
  -v $(pwd)/registry:/var/lib/registry \
  registry:2.7
sudo docker run --rm -it --name docker-registry-ui --network registry -e ENV_DOCKER_REGISTRY_HOST=docker-registry -e ENV_REGISTRY_PORT=5000 -p 8080:80 konradkleine/docker-registry-frontend:v2
