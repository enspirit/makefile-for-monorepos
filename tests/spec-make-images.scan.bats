#!/usr/bin/env bats

load test_helper

@test "'make images.scan' scans all images" {
  run make images.scan
  [ "$status" -eq 0 ]
  has_scanned monorepo/api
  has_scanned monorepo/base
  has_scanned monorepo/frontend
  has_scanned monorepo/tests
}

