#!/usr/bin/env bats

load test_helper

@test "'make <comp>.up' builds a component if needed" {
  make api.up
  has_built monorepo/api
}

@test "'make <comp>.up' deletgates to docker-compose up" {
  make api.up
  has_upped api
}

@test "'make <comp>.up' fails for components not present in docker-compose" {
  run make base.up
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

@test "'make <comp>.up' fails for unknown components" {
  run make unknown.up
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

