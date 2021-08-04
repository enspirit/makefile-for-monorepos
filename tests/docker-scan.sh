#!/usr/bin/env bash

###
### This script mocks docker scan and is used as DOCKER_SCAN
### when running the tests
###

echo "image=$1" >> ./tests/docker-scan.log

exit 0
