#!/usr/bin/env bats

load test_helper

@test "'make images' builds all images" {
  run make images
  [ "$status" -eq 0 ]
  has_built monorepo/base
  has_built monorepo/api
  has_built monorepo/frontend
  has_built monorepo/tests
}

@test "'make images' does not rebuild images when unnecessary" {
  run make images
  [ "$status" -eq 0 ]
  has_built monorepo/api
  has_built monorepo/base

  clear_build_logs

  run make images
  [ "$status" -eq 0 ]
  has_not_built monorepo/api
  has_not_built monorepo/base
}
