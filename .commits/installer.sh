#!/bin/bash

args=$@
curl -fsSL https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/.commits/install.sh | bash -s $args
