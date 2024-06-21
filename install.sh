#!/bin/bash

root_password=$1

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY="/registry" \
  -v ./registry:/registry \
  registry:2.7
