#!/usr/bin/env bash
set -e

REMOTE="gdrive:image-search/images"
DEST="/data/master_images"

mkdir -p "$DEST"

rclone copy "$REMOTE" "$DEST" --drive-chunk-size 64M --transfers 8 --checkers 8 --max-age 0

echo "Sync complete: $REMOTE -> $DEST"
