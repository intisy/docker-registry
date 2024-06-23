#!/bin/bash

args=$@

execute() {
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/docker-registry/commits?per_page=2 | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/.commits/$sha/install.sh"
  echo "Executing: $url"
  curl -fsSL $url | bash -s $args
  if [[ $? -ne 0 ]]; then
    execute
  fi
}
execute
