#!/usr/bin/env bats

load test_helper

@test "'make <comp>.clean' removes sentinel files" {
  make api.image
  run make clean
  [ ! -e .build/api/Dockerfile.built ]
}
