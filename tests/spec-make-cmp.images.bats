#!/usr/bin/env bats

load test_helper

@test "'make <comp>.images' works" {
  run make api.images
  [ "$status" -eq 0 ]
  has_built monorepo/api
}

@test "'make <comp>.images' fails for unknown components" {
  run make unknown.images
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

@test "'make <comp>.images' builds subcomponent images too" {
  run make multiple.images
  [ "$status" -eq 0 ]
  has_built monorepo/multiple
  has_built monorepo/multiple.engine
}
