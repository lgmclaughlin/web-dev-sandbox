#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONTENT_MOUNT="$SCRIPT_DIR/../workspace/content"
CONTENT_PATH=""

manage_mount() {
    local remote=$1
    local local_path=$2

	echo "Verifying $local_path..."
    if ! mountpoint -q "$local_path"; then
        fusermount3 -u -z "$local_path" 2>/dev/null
        sleep 1
        sshfs "$remote" "$local_path" \
            -o allow_other,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,uid=$(id -u),gid=$(id -g)
    fi
}

manage_mount "$CONTENT_PATH" "$CONTENT_MOUNT"
manage_mount "$SCHEMA_PATH" "$SCHEMA_MOUNT"
