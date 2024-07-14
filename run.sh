#!/bin/bash

action=$1
pat=$2
arg=$3
using_kubernetes=true
using_ui=true
using_docker_ui_test=false
gererate_password=false

execute() {
  substring="#!/bin/bash"
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/docker-registry/commits?per_page=2 | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/.commits/$sha/scripts/$action.sh"
  echo "Executing: $url"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring ]]; then
    if [ -n "$pat" ]; then
      curl -X GET -H "Authorization: Bearer $pat" -H "Content-Type: application/json" -fsSL $url | bash -s $sha $using_kubernetes $using_ui $using_docker_ui_test $gererate_password $arg
    else
      curl -fsSL $url | bash -s $sha $using_kubernetes $using_ui $using_docker_ui_test $gererate_password $arg
    fi
  else
    sleep 1
    execute
  fi
}
execute
