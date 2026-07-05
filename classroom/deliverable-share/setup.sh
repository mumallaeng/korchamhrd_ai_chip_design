#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON:-python3}"
VENV_DIR="$ROOT_DIR/.venv"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Python not found: $PYTHON_BIN" >&2
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/python" -m pip install --no-cache-dir -r "$ROOT_DIR/requirements.txt"

cat <<EOF
Setup complete.

Next steps:
  cp "$ROOT_DIR/examples/config.sample.json" "$ROOT_DIR/config.local.json"
  edit "$ROOT_DIR/config.local.json"
  $ROOT_DIR/run.sh scan --config "$ROOT_DIR/config.local.json" --scope all
EOF
