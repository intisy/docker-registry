#!/bin/bash

action=$1
arg=$2

execute() {
  substring="The requested URL returned error"
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/docker-registry/commits?per_page=2 | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/.commits/$sha/$action.sh"
  echo "Executing: $url"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring ]]; then
    sleep 1
    execute
  else
    curl -fsSL $url | bash -s $arg
  fi
}
execute
