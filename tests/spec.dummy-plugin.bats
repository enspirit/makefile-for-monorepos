#!/usr/bin/env bats

load test_helper

@test "(dummy plugin) 'make dummy' works" {
  run make dummy
  [ "$status" -eq 0 ]
}

@test "(dummy plugin) 'make <comp>.dummy.example' works" {
  run make api.dummy.example
  [ "$status" -eq 0 ]
  echo $output
  [ "$output" = "Some dummy example for api" ]
}

