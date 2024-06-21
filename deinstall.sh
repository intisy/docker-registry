#!/bin/bash

sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=registry --format="{{.ID}}"))
sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=konradkleine/docker-registry-frontend:v2 --format="{{.ID}}"))
sudo rm -r ~/docker-registry
