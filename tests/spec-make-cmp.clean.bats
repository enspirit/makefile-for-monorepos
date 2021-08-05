#!/usr/bin/env bats

load test_helper

@test "'make <comp>.clean' works" {
  run make api.clean
  [ "$status" -eq 0 ]
}

@test "'make <comp>.clean' fails for unknown components" {
  run make unknown.clean
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

