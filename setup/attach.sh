#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR"/../docker/.env

docker compose -p "$COMPOSE_PROJECT_NAME" exec sandbox bash -lc "bash"
