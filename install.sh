#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
# sudo docker run --rm --entrypoint htpasswd registry:2 -Bbn root "root" > ~/docker-registry/auth/registry.password
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry \
  # -e REGISTRY_AUTH="htpasswd" \
  # -e REGISTRY_AUTH_HTPASSWD_REALM="Registry" \
  # -e REGISTRY_AUTH_HTPASSWD_PATH="/auth/registry.password" \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY="/registry" \
  -v ./registry:/registry \
  # -v ./auth:/auth \
  registry:2.7
# sudo docker run --name docker-registry-ui \
#   -d --network host --restart=always \
#   -e ENV_DOCKER_REGISTRY_HOST=127.0.0.1 \
#   -e ENV_DOCKER_REGISTRY_PORT=5000 \
#   konradkleine/docker-registry-frontend:v2
