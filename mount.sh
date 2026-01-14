#!/bin/bash

CONTENT_MOUNT="workspace/content"
CONTENT_PATH=""

cleanup_mount() {
    local target=$1
    echo "Cleaning up $target..."
    fusermount3 -u -z "$target" 2>/dev/null || umount -l "$target" 2>/dev/null
}

cleanup_mount "$CONTENT_MOUNT"

sleep 2

echo "Mounting $CONTENT_PATH..."
sshfs "$CONTENT_PATH" "$CONTENT_MOUNT" \
    -o allow_other,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,uid=$(id -u),gid=$(id -g)

echo "Done."
