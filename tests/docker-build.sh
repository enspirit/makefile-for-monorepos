#!/usr/bin/env bash

###
### This script mocks docker build and is used as DOCKER_BUILD_CMD
### when running the tests
###

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -f)
      DOCKERFILE="$2"
      shift # past argument
      shift # past value
      ;;
    -t)
      DOCKERTAG="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      CONTEXT="$1"
      shift # past value
      ;;
  esac
done

echo "dockerfile=$DOCKERFILE,tag=$DOCKERTAG,context=$CONTEXT" >> ./tests/docker-build.log

exit 0
