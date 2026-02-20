#!/bin/bash
if [ -f .custom_config ]
then
         . ./.custom_config
fi
# convert long options to short
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--recreate") set -- "$@" "-r" ;;
    *) set -- "$@" "$arg"
  esac
done

display_usage()
{
   echo "Start application containers"
   echo
   echo "Options:"
   echo "-h|--help      Print this help"
   echo "-r|--recreate  Recreate containers"
   echo
}

if [[ -z ${@} ]]
 then
 	display_usage
    exit 0
fi

while getopts "hr" option; do
    case "${option}"
        in
            r) RECREATE=true;;
            h) display_usage
               exit 0;;
            *) display_usage
               exit 0;;
    esac
done

# load configuration
typeset ENVFILE=.env

if [[ ! -f "${ENVFILE}" ]]; then 
	cp .env_default ${ENVFILE}
fi

. ./.env

export DOCKER_COMPOSE_FILE="docker-compose.yml"

if [[ ! -f $DOCKER_COMPOSE_FILE ]]; then
    echo "Could not find ${DOCKER_COMPOSE_FILE} configuration file"
fi

if [[ ${RECREATE:-false} = true ]]; then
    # Stopping already running containers
    echo "docker-compose -f ${DOCKER_COMPOSE_FILE} down"
    docker compose -f ${DOCKER_COMPOSE_FILE} down

    printf "\n"

    # Building images
    echo "docker-compose -f ${DOCKER_COMPOSE_FILE} build --force-rm"
    docker compose -f ${DOCKER_COMPOSE_FILE} build --force-rm 
fi

EXIT_CODE=$?

if [[ ${EXIT_CODE} -eq 0 ]]; then
    printf "\n"

    # Starting containers
    echo "docker-compose -f ${DOCKER_COMPOSE_FILE} up --no-build --detach"
    docker compose -f ${DOCKER_COMPOSE_FILE} up --no-build --detach

    EXIT_CODE=$?
fi

printf "\n"

if [[ ${EXIT_CODE} -eq 0 ]]; then
    printf "\n"
    echo "Container running on: $(hostname)"
    printf "\n"
fi

exit ${EXIT_CODE}
