#!/usr/bin/env bats

load test_helper

@test "'make <comp>.down' deletgates to docker-compose stop" {
  make api.down
  has_downed api
}
