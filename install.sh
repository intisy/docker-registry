#!/bin/bash

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry-data auth
cd auth
sudo apt install apache2-utils -y
sudo htpasswd -b -c registry.password admin password
cd ..
sudo curl -o docker-compose.yaml https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/docker-compose.yaml
sudo docker compose up -d
