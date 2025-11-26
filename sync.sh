#!/usr/bin/env bash
set -euo pipefail

# jika rclone tidak ada, download & extract (Linux x86_64)
if ! command -v rclone >/dev/null 2>&1; then
  echo "rclone not found, downloading..."
  RCLONE_VER="v1.72.0"
  wget -q https://downloads.rclone.org/${RCLONE_VER}/rclone-${RCLONE_VER}-linux-amd64.zip -O /tmp/rclone.zip
  unzip -q /tmp/rclone.zip -d /tmp
  chmod +x /tmp/rclone-*-linux-amd64/rclone
  mv /tmp/rclone-*-linux-amd64/rclone /usr/local/bin/rclone
  echo "rclone installed"
fi

# create temporary rclone config from env vars
mkdir -p /tmp/.rclone
cat > /tmp/.rclone/rclone.conf <<EOF
[gdrive]
type = ${RCLONE_CONFIG_GDRIVE_TYPE:-drive}
scope = ${RCLONE_CONFIG_GDRIVE_SCOPE:-drive}
token = ${RCLONE_CONFIG_GDRIVE_TOKEN}
EOF

export RCLONE_CONFIG=/tmp/.rclone/rclone.conf

REMOTE="gdrive:image-search/images"
DEST="/data/master_images"
mkdir -p "$DEST"

# use copy to avoid accidental deletes on remote
rclone copy "$REMOTE" "$DEST" --drive-chunk-size 64M --transfers 8 --checkers 8 --quiet

echo "Sync complete: $REMOTE -> $DEST"
