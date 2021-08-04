#!/usr/bin/env bats

load test_helper

@test "'make <comp>.scan' works" {
  run make api.scan
  [ "$status" -eq 0 ]
  has_scanned monorepo/api
}

@test "'make <comp>.scan' fails for unknown components" {
  run make unknown.scan
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

@test "'make <comp>.scan' builds image first" {
  run make api.scan
  has_built monorepo/api
  has_scanned monorepo/api
}

@test "'make <comp>.scan' scans the latest tag by default" {
  make api.scan
  has_scanned monorepo/api:latest
}

@test "'make <comp>.scan' scans the appropriate tag when DOCKER_TAG is overriden" {
  DOCKER_TAG=test make api.scan
  has_scanned monorepo/api:test
}
