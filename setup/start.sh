#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

$SCRIPT_DIR/mount.sh && \
$SCRIPT_DIR/../docker/docker.sh && \
docker exec -it web-dev-sandbox bash -c "source ~/.bashrc && bash"
