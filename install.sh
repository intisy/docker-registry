#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
cd auth
sudo apt install apache2-utils -y
htpasswd -cB registry.htpasswd root root
cd ..
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/registry/auth.htpasswd \
  -v ./auth/registry.htpasswd:/registry/auth.htpasswd \
  -v ./registry:/registry \
  registry:2.7
