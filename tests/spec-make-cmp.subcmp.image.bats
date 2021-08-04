#!/usr/bin/env bats

load test_helper

@test "'make <comp>.<subcomponent>.image' works" {
  run make multiple.engine.image
  [ "$status" -eq 0 ]
  has_built monorepo/multiple.engine
}

@test "'make <comp>.<subcomponent>.image' fails for unknown subcomponents" {
  run make unknown.subcompnent.image
  [ "$status" -eq 2 ]
  echo $output | grep "No rule to make target"
}

@test "'make <comp>.<subcomponent>.image' builds the latest tag by default" {
  make multiple.engine.image
  has_built monorepo/multiple.engine:latest
}

@test "'make <comp>.<subcomponent>.image' builds the appropriate tag when DOCKER_TAG is overriden" {
  DOCKER_TAG=test make multiple.engine.image
  has_built monorepo/multiple.engine:test
}
