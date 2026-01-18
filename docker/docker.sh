#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR"/.env

export USER_ID="$(id -u)"
export GROUP_ID="$(id -g)"

SHOULD_BUILD=false
if [ "$#" -gt 0 ]; then
	if [[ "$#" -gt 1 || "$1" != "--build" ]]; then
		echo "Usage: ./docker.sh [--build]"
		exit 1
	fi
	SHOULD_BUILD=true
fi

if [ -n "$(docker compose -p "$COMPOSE_PROJECT_NAME" -f "$SCRIPT_DIR/docker-compose.yml" ps -q sandbox)" ]; then
    echo "Bringing down existing container..."
    docker compose -p "$COMPOSE_PROJECT_NAME" -f "$SCRIPT_DIR/docker-compose.yml" down
fi

if $SHOULD_BUILD; then
	echo "Building Docker image for ${COMPOSE_PROJECT_NAME}..."
	docker compose -f "$SCRIPT_DIR/docker-compose.yml" build
fi

echo "Starting ${COMPOSE_PROJECT_NAME} container..."
docker compose -p "$COMPOSE_PROJECT_NAME" -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo "Done."
