#!/usr/bin/env bash

###
### This script mocks docker-compose and is used as DOCKER_COMPOSE
### when running the tests
###
echo $@ >> /tmp/invocations
COMMAND=$1
shift

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --force-recreate)
      FORCERECREATE="true"
      shift # past argument
      ;;
    -d)
      DETACT="true"
      shift # past argument
      ;;
    *)
      COMPONENT="$1"
      shift # past value
      ;;
  esac
done

## Asking for the list of components?
if [ "$COMMAND" == "config" ]; then
  echo "api tests"
fi

echo "command=$COMMAND,component=$COMPONENT" >> ./tests/docker-compose.log

exit 0
