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

# create temporary rclone config from env vars using python to avoid quoting issues
mkdir -p /tmp/.rclone
python3 - <<'PY'
import os, json, sys
tok = os.environ.get("RCLONE_CONFIG_GDRIVE_TOKEN")
if not tok:
    print("ERROR: environment variable RCLONE_CONFIG_GDRIVE_TOKEN is empty", file=sys.stderr)
    sys.exit(1)
# tok is expected to be a JSON string like: {"access_token":"...","refresh_token":"...","expiry":"..."}
# We will write the config file with token = <json>
conf_path = "/tmp/.rclone/rclone.conf"
with open(conf_path, "w", encoding="utf-8") as f:
    f.write("[gdrive]\n")
    f.write("type = " + os.environ.get("RCLONE_CONFIG_GDRIVE_TYPE", "drive") + "\n")
    f.write("scope = " + os.environ.get("RCLONE_CONFIG_GDRIVE_SCOPE", "drive") + "\n")
    # write token exactly as provided (no additional quoting)
    f.write("token = " + tok + "\n")
print("Wrote rclone config to", conf_path)
PY

export RCLONE_CONFIG=/tmp/.rclone/rclone.conf

REMOTE="gdrive:image-search/images"
DEST="/data/master_images"
mkdir -p "$DEST"

echo "Starting rclone copy from $REMOTE to $DEST ..."
# quiet flag optional; keep normal output for logs
rclone copy "$REMOTE" "$DEST" --drive-chunk-size 64M --transfers 8 --checkers 8 --timeout 1m

echo "Sync complete: $REMOTE -> $DEST"
