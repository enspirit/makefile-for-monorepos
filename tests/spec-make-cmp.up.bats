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
