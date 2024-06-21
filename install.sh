#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
sudo docker run --rm --entrypoint htpasswd registry:2 -Bbn root "$root_password" > ~/docker-registry/auth/registry.password
sudo docker run -d -p 718:5000 --network host --restart=always --name registry \
-e REGISTRY_AUTH="htpasswd" \
-e REGISTRY_AUTH_HTPASSWD_REALM="Registry" \
-e REGISTRY_AUTH_HTPASSWD_PATH="/auth/registry.password" \
-e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY="/registry" \
-v ./registry:/registry \
-v ./auth:/auth registry:2
sudo docker compose up -d
