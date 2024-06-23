#!/bin/bash

args=$@
sha=$(git ls-remote https://github.com/WildePizza/docker-registry HEAD | awk {'print $1'})
curl -fsSL https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/.commits/$sha/install.sh | bash -s $args
