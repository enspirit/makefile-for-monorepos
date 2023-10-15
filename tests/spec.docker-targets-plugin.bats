#!/usr/bin/env bats

load test_helper

@test "(docker-targets plugin) 'make <comp>.<target>.image' works (multistage.builder)" {
  run make multistage.builder.image
  [ "$status" -eq 0 ]
  has_built monorepo/multistage.builder
}

@test "(docker-targets plugin) 'make <comp>.<target>.image' works (multistage.production)" {
  run make multistage.production.image
  [ "$status" -eq 0 ]
  has_built monorepo/multistage.production
}

@test "(docker-targets plugin) 'make <comp>.<target>.clean' works" {
  run make multistage.builder.clean
  [ "$status" -eq 0 ]
}

@test "(docker-targets plugin) 'make images' builds targets" {
  run make images
  [ "$status" -eq 0 ]
  has_built monorepo/multistage.builder
  has_built monorepo/multistage.production
}

@test "'make <comp>.<target>.image' rebuilds when file dependencies change" {
  make multistage.builder.image
  has_built monorepo/multistage.builder

  clear_build_logs
  touch multistage/Dockerfile

  make multistage.builder.image
  has_built monorepo/multistage.builder
}

@test "'make <comp>.<target>.image' does not rebuild when not necessary" {
  make multistage.builder.image
  has_built monorepo/multistage.builder

  clear_build_logs

  make multistage.builder.image
  has_not_built monorepo/multistage.builder
}

