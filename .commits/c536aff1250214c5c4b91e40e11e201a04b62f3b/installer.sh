#!/bin/bash

args=$@

execute() {
  substring="The requested URL returned error"
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/docker-registry/commits?per_page=2 | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/.commits/$sha/install.shh"
  echo "Executing: $url"
  output=$(curl -fsSL $url | bash -s $args >&2)
  if [[ $output =~ $substring ]]; then
    execute
  fi
}
execute
