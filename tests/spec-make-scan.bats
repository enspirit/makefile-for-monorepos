#!/usr/bin/env bats

load test_helper

@test "'make scan' scans all images" {
  run make scan
  [ "$status" -eq 0 ]
  has_scanned monorepo/api
  has_scanned monorepo/base
  has_scanned monorepo/frontend
  has_scanned monorepo/tests
}

