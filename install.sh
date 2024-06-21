#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
docker run --rm --entrypoint htpasswd registry:2 -Bbn root root > ~/docker-registry/auth/registry.password
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/registry/auth.htpasswd \
  -v ./auth/registry.htpasswd:/registry/auth.htpasswd \
  -v ./registry:/registry \
  registry:2.7
