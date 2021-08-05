#!/usr/bin/env bats

load test_helper

@test "'make <comp>.image.scan' works" {
  run make api.image.scan
  [ "$status" -eq 0 ]
  has_scanned monorepo/api
}

@test "'make <comp>.image.scan' fails for unknown components" {
  run make unknown.image.scan
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

@test "'make <comp>.image.scan' builds image first" {
  run make api.image.scan
  has_built monorepo/api
  has_scanned monorepo/api
}

@test "'make <comp>.image.scan' scans the latest tag by default" {
  make api.image.scan
  has_scanned monorepo/api:latest
}

@test "'make <comp>.image.scan' scans the appropriate tag when DOCKER_TAG is overriden" {
  DOCKER_TAG=test make api.image.scan
  has_scanned monorepo/api:test
}
