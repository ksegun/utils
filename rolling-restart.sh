#!/bin/bash

# strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

namespace=default
container=
#num_procs=4
deployment_name=

while getopts ":n:p:d:" opt; do
  case ${opt} in
    n )
      namespace=$OPTARG
      ;;
    d )
      deployment_name=$OPTARG
      ;;
    p )
      num_procs=$OPTARG
      ;;
    \? )
      echo "Usage dumpLogs.sh [-h] [-n <namespace>] [-c <container>] [-d <deployment name>]"
      exit 0
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

#num_jobs="\j"

function getDeployments() {
  if [ -n "$deployment_name" ]; then
    d=$(kubectl -n "$namespace" get deployment --no-headers | grep "$deployment_name" | cut -d" " -f1)
    echo "$d"
  else
    d=$(kubectl -n "$namespace" get deployment --no-headers | cut -d" " -f1)
    echo "$d"
  fi
}

for i in $(getDeployments); do 
    echo "restarting deployment $i"
    kubectl -n "$namespace" rollout restart deployment "$i" &
done
wait