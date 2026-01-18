#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHITELIST_FILE="$SCRIPT_DIR/whitelist.txt"
DID_BUILD=false

source "$SCRIPT_DIR"/.env

if [ -z "$(docker compose -p "$COMPOSE_PROJECT_NAME" -f "$SCRIPT_DIR/docker-compose-firewall.yml" ps -q firewall)" ]; then
    echo "Starting $COMPOSE_PROJECT_NAME container..."
    docker compose -p "$COMPOSE_PROJECT_NAME" -f "$SCRIPT_DIR/docker-compose-firewall.yml" up -d --build
    DID_BUILD=true
    sleep 2
fi

CONTAINER_ID="$(docker compose -p "$COMPOSE_PROJECT_NAME" -f "$SCRIPT_DIR/docker-compose-firewall.yml" ps -q firewall)"

if $DID_BUILD; then
    echo "Initializing firewall..."
    docker exec "$CONTAINER_ID" /usr/local/bin/firewall-init.sh
fi

echo "Applying firewall whitelist..."
docker cp "$WHITELIST_FILE" "$CONTAINER_ID:/etc/firewall/whitelist.txt"
docker exec "$CONTAINER_ID" /usr/local/bin/firewall-apply.sh
