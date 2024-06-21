#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry-data auth certs
docker run --rm --entrypoint htpasswd registry:2 -Bbn root "$root_password" > ~/docker-registry/auth/registry.password
sudo curl -o docker-compose.yaml https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/docker-compose.yaml
sudo docker compose up -d
