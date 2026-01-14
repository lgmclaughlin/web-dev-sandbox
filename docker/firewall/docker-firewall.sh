#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW_CONTAINER="sandbox-firewall"
WHITELIST_FILE="$SCRIPT_DIR/whitelist.txt"

if ! docker ps --format '{{.Names}}' | grep -q "^$FW_CONTAINER\$"; then
	echo "Starting $FW_CONTAINER container..."

	docker compose -f "$SCRIPT_DIR/docker-compose-firewall.yml" up -d --build
	sleep 2

	echo "Firewall container is running. Initializing..."

	docker exec "$FW_CONTAINER" /usr/local/bin/firewall-init.sh
fi

docker cp "$WHITELIST_FILE" "$FW_CONTAINER:/etc/firewall/whitelist.txt"
docker exec "$FW_CONTAINER" /usr/local/bin/firewall-apply.sh
