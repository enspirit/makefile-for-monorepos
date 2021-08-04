#!/usr/bin/env bats

load test_helper

@test "'make <comp>.image' works" {
  run make api.image
  [ "$status" -eq 0 ]
  has_built monorepo/api
}

@test "'make <comp>.image' fails for unknown components" {
  run make unknown.image
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

@test "'make <comp>.image' builds dependencies first" {
  run make api.image
  has_built monorepo/base
}

@test "'make <comp>.image' doesn't rebuild when unnecessary" {
  make api.image
  has_built monorepo/api

  clear_build_logs

  make api.image
  has_not_built monorepo/api
}

@test "'make <comp>.image' rebuilds when component deps change" {
  make api.image
  has_built monorepo/api

  clear_build_logs
  touch base/Dockerfile

  make api.image
  has_built monorepo/api
}

@test "'make <comp>.image' rebuilds when file dependencies change" {
  make api.image
  has_built monorepo/api

  clear_build_logs
  touch api/index.js

  make api.image
  has_built monorepo/api
}
