#!/usr/bin/env bash
set -euo pipefail

echo "Starting sync.sh"

# if rclone exists, use it
if command -v rclone >/dev/null 2>&1; then
  echo "rclone already installed"
else
  echo "rclone not found, attempting to download and install using available tools..."

  RCLONE_VER="v1.72.0"
  RCLONE_ZIP="/tmp/rclone-${RCLONE_VER}.zip"
  RCLONE_URL="https://downloads.rclone.org/${RCLONE_VER}/rclone-${RCLONE_VER}-linux-amd64.zip"

  # try curl
  if command -v curl >/dev/null 2>&1; then
    echo "Downloading rclone with curl..."
    curl -sSL "$RCLONE_URL" -o "$RCLONE_ZIP"
  # try wget
  elif command -v wget >/dev/null 2>&1; then
    echo "Downloading rclone with wget..."
    wget -q -O "$RCLONE_ZIP" "$RCLONE_URL"
  else
    # fallback to python downloader (should exist)
    echo "Downloading rclone using python urllib..."
    python3 - <<PYCODE
import urllib.request, sys
url = "${RCLONE_URL}"
out = "${RCLONE_ZIP}"
print("Downloading", url, "->", out)
urllib.request.urlretrieve(url, out)
print("Downloaded")
PYCODE
  fi

  # extract rclone binary using python (no unzip dependency)
  echo "Extracting rclone..."
  python3 - <<PYUNZIP
import zipfile, glob, os, shutil
zpath = "${RCLONE_ZIP}"
with zipfile.ZipFile(zpath, 'r') as z:
    members = z.namelist()
    # find the rclone binary path inside zip
    candidates = [m for m in members if m.endswith('/rclone') or m.endswith('\\rclone') or m == 'rclone']
    if not candidates:
        # try any 'rclone-*-linux-amd64/rclone'
        for m in members:
            if m.endswith('/rclone'):
                candidates.append(m)
    if not candidates:
        raise SystemExit("rclone binary not found in zip")
    src = candidates[0]
    print("Found in zip:", src)
    z.extract(src, "/tmp")
    extracted = os.path.join("/tmp", src)
    dest = "/usr/local/bin/rclone"
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.move(extracted, dest)
    os.chmod(dest, 0o755)
    print("rclone installed to", dest)
# cleanup zip
os.remove("${RCLONE_ZIP}")
PYUNZIP

  echo "rclone installed"
fi

# create temporary rclone config from env vars (Railway env vars)
mkdir -p /tmp/.rclone
cat > /tmp/.rclone/rclone.conf <<'EOF'
[gdrive]
type = ${RCLONE_CONFIG_GDRIVE_TYPE:-drive}
scope = ${RCLONE_CONFIG_GDRIVE_SCOPE:-drive}
token = ${RCLONE_CONFIG_GDRIVE_TOKEN}
EOF

export RCLONE_CONFIG=/tmp/.rclone/rclone.conf

REMOTE="gdrive:image-search/images"
DEST="/data/master_images"
mkdir -p "$DEST"

echo "Starting rclone copy from $REMOTE to $DEST ..."
# quiet flag optional; keep normal output for logs
rclone copy "$REMOTE" "$DEST" --drive-chunk-size 64M --transfers 8 --checkers 8 --timeout 1m

echo "Sync complete: $REMOTE -> $DEST"
