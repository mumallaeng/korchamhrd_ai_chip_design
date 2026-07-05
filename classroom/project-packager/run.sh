#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VENV_PY="$SCRIPT_DIR/.venv/bin/python"

if [ ! -x "$VENV_PY" ]; then
  echo "error: missing virtualenv. Run ./setup.sh first." >&2
  exit 1
fi

exec "$VENV_PY" "$SCRIPT_DIR/project_packager.py" "$@"
