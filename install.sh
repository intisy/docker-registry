#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry-data auth certs
docker run --rm --entrypoint htpasswd registry:2 -Bbn root "$root_password" > ~/docker-registry/auth/registry.password
sudo curl -o docker-compose.yaml https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/docker-compose.yaml
docker run --name docker-registry-ui \
  -d --network host --restart=always \
  -e ENV_DOCKER_REGISTRY_HOST=127.0.0.1 \
  -e ENV_DOCKER_REGISTRY_PORT=5000 \
  konradkleine/docker-registry-frontend:v2
sudo docker compose up -d
