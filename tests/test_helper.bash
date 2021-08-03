export DOCKER_BUILD="./tests/docker-build.sh"
export DOCKER_COMPOSE="./tests/docker-compose.sh"

setup() {
  rm -rf .build
  clear_wrapper_logs
}

clear_wrapper_logs() {
  clear_build_logs
  clear_compose_logs
}

clear_build_logs() {
  echo "" > tests/docker-build.log
}

clear_compose_logs() {
  echo "" > tests/docker-compose.log
}

has_built() {
  grep "tag=$1" tests/docker-build.log
}

has_not_built() {
  ! grep "tag=$1" tests/docker-build.log
}

has_upped() {
  grep "command=up,component=$1" tests/docker-compose.log
}

has_downed() {
  grep "command=stop,component=$1" tests/docker-compose.log
}

