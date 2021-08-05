#!/usr/bin/env bats

load test_helper

@test "(subcomponent plugin) 'make <comp>.<subcomp>.image' works" {
  run make frontend.builder.image
  [ "$status" -eq 0 ]
  has_built monorepo/frontend.builder
}

@test "(subcomponent plugin) 'make <comp>.<subcomp>.clean' works" {
  run make frontend.builder.clean
  [ "$status" -eq 0 ]
}

@test "(subcomponent plugin) 'make images' builds subcomponents" {
  run make images
  [ "$status" -eq 0 ]
  has_built monorepo/frontend.builder
}
