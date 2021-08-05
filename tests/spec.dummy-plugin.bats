#!/usr/bin/env bats

load test_helper

@test "'make dummy' works" {
  run make dummy
  [ "$status" -eq 0 ]
}

@test "'make <comp>.dummy.example' works" {
  run make api.dummy.example
  [ "$status" -eq 0 ]
  echo $output
  [ "$output" = "Some dummy example for api" ]
}
