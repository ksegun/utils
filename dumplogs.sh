#!/bin/bash

# strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

namespace=default
container=
#num_procs=4
deployment_name=

while getopts ":n:c:d:" opt; do
  case ${opt} in
    n )
      namespace=$OPTARG
      ;;
    c )
      container=$OPTARG
      ;;
    d )
      deployment_name=$OPTARG
      ;;
#    p )
#      num_procs=$OPTARG
#      ;;
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
   for j in $(kubectl -n "$namespace" get po --no-headers | grep "$i" | cut -d" " -f1); do
       if [ -z "$container" ]; then
           echo "downloading logs for pod $j to $j.log.gz"
           kubectl -n "$namespace" logs "$j" --all-containers=true --prefix | gzip -9c > "$j".log.gz &
       else
           echo "downloading logs for container $container in pod $j ito $j-$container.log.gz"
           kubectl -n "$namespace" -c "$container" logs "$j" --prefix | gzip -9c > "$j"-container.log.gz &
       fi
   done
   wait
done
