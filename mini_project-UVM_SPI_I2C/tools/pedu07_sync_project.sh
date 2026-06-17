#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-korcham-server-pedu07}"
REMOTE_PROJECT_DIR="${REMOTE_PROJECT_DIR:-/home/pedu07/projects/SPI_I2C_UVM}"

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_path="$(mktemp -t spi_i2c_uvm.XXXXXX.tar.gz)"
trap 'rm -f "$package_path"' EXIT

(
  cd "$project_root"
  export COPYFILE_DISABLE=1
  export COPY_EXTENDED_ATTRIBUTES_DISABLE=1
  tar --format=ustar -czf "$package_path" \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='csrc' \
    --exclude='simv' \
    --exclude='simv.*' \
    --exclude='simv_*' \
    --exclude='*.daidir' \
    --exclude='*.vdb' \
    --exclude='cov_report' \
    --exclude='wave' \
    --exclude='verdiLog' \
    --exclude='*.log' \
    --exclude='*.key' \
    --exclude='DVEfiles' \
    .
)

encoded_payload="$(base64 -i "$package_path")"

ssh -T -o BatchMode=yes -o ConnectTimeout=8 "$REMOTE_HOST" <<REMOTE_SCRIPT
set -e

tmp_package=\$(mktemp /tmp/spi_i2c_uvm_sync.XXXXXX.tar.gz)
cat > "\$tmp_package.b64" <<'B64_PAYLOAD'
$encoded_payload
B64_PAYLOAD
base64 -d "\$tmp_package.b64" > "\$tmp_package"
rm -f "\$tmp_package.b64"

rm -rf "$REMOTE_PROJECT_DIR"
mkdir -p "$REMOTE_PROJECT_DIR"
tar -xzf "\$tmp_package" -C "$REMOTE_PROJECT_DIR"
rm -f "\$tmp_package"

echo "== pedu07 sync complete =="
printf 'user=%s\n' "\$(whoami)"
printf 'host=%s\n' "\$(hostname)"
printf 'project=%s\n' "$REMOTE_PROJECT_DIR"
printf 'makefile=%s\n' "\$(test -f "$REMOTE_PROJECT_DIR/Makefile" && echo OK || echo MISSING)"
REMOTE_SCRIPT
