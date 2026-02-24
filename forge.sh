#!/bin/bash
set -euo pipefail

if [[ -f .custom_config ]]; then
  # shellcheck disable=SC1091
  . ./.custom_config
fi

display_usage() {
  echo "Start application containers"
  echo
  echo "Options:"
  echo "-h|--help               Print this help"
  echo "-r|--recreate           Recreate containers"
  echo "-b|--build              Build image"
  echo "-n|--build-no-cache     Build image"
  echo "-d|--down               Down containers"
  echo "-u|--up                 Up containers"
  echo
}

# Convert long options to short options.
for arg in "$@"; do
  shift
  case "$arg" in
    --help) set -- "$@" -h ;;
    --recreate) set -- "$@" -r ;;
    --build) set -- "$@" -b ;;
    --build-no-cache) set -- "$@" -n ;;
    --down) set -- "$@" -d ;;
    --up) set -- "$@" -u ;;
    *) set -- "$@" "$arg" ;;
  esac
done

if [[ $# -eq 0 ]]; then
  display_usage
  exit 0
fi

RECREATE=false
DO_BUILD=false
DO_BUILD_NO_CACHE=false
DO_DOWN=false
DO_UP=false

while getopts "hrbndu" option; do
  case "${option}" in
    r) RECREATE=true ;;
    b) DO_BUILD=true ;;
    n) DO_BUILD_NO_CACHE=true ;;
    d) DO_DOWN=true ;;
    u) DO_UP=true ;;
    h)
      display_usage
      exit 0
      ;;
    *)
      display_usage
      exit 1
      ;;
  esac
done

ENVFILE=".env"
if [[ -f "${ENVFILE}" ]]; then
  # shellcheck disable=SC1090
  . "./${ENVFILE}"
elif [[ -f ".env_default" ]]; then
  cp .env_default "${ENVFILE}"
  # shellcheck disable=SC1090
  . "./${ENVFILE}"
fi

DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
if [[ ! -f "${DOCKER_COMPOSE_FILE}" ]]; then
  echo "Could not find ${DOCKER_COMPOSE_FILE} configuration file"
  exit 1
fi

compose_build() {
  local build_args=("$@")

  if docker compose -f "${DOCKER_COMPOSE_FILE}" build "${build_args[@]}"; then
    return 0
  fi

  echo
  echo "Build with BuildKit/buildx failed, retrying with classic builder..."
  DOCKER_BUILDKIT=0 COMPOSE_DOCKER_CLI_BUILD=0 \
    docker compose -f "${DOCKER_COMPOSE_FILE}" build "${build_args[@]}"
}

if [[ "${RECREATE}" == "true" ]]; then
  DO_DOWN=true
  DO_BUILD=true
  DO_UP=true
fi

# --build-no-cache implies build
if [[ "${DO_BUILD_NO_CACHE}" == "true" ]]; then
  DO_BUILD=true
fi

# Default behavior when no action flags are passed.
if [[ "${DO_DOWN}" == "false" && "${DO_BUILD}" == "false" && "${DO_UP}" == "false" ]]; then
  DO_BUILD=true
  DO_UP=true
fi

if [[ "${DO_DOWN}" == "true" ]]; then
  echo "docker compose -f ${DOCKER_COMPOSE_FILE} down"
  docker compose -f "${DOCKER_COMPOSE_FILE}" down
fi

if [[ "${DO_BUILD}" == "true" ]]; then
  echo
  if [[ "${DO_BUILD_NO_CACHE}" == "true" ]]; then
    echo "docker compose -f ${DOCKER_COMPOSE_FILE} build --force-rm --no-cache"
    compose_build --force-rm --no-cache
  else
    echo "docker compose -f ${DOCKER_COMPOSE_FILE} build --force-rm"
    compose_build --force-rm
  fi
fi

if [[ "${DO_UP}" == "true" ]]; then
  echo
  if [[ "${DO_BUILD}" == "true" ]]; then
    echo "docker compose -f ${DOCKER_COMPOSE_FILE} up --no-build --detach"
    docker compose -f "${DOCKER_COMPOSE_FILE}" up --no-build --detach
  else
    echo "docker compose -f ${DOCKER_COMPOSE_FILE} up --detach"
    docker compose -f "${DOCKER_COMPOSE_FILE}" up --detach
  fi

  echo
  echo "Container running on: $(hostname)"
fi
