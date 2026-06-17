#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-korcham-server-pedu07}"
REMOTE_PROJECT_DIR="${REMOTE_PROJECT_DIR:-/home/pedu07/projects/SPI_I2C_UVM}"
REMOTE_VCS_HOME="${REMOTE_VCS_HOME:-/tools/synopsys/vcs/W-2024.09-SP2}"
REMOTE_VERDI_HOME="${REMOTE_VERDI_HOME:-/tools/synopsys/verdi/X-2025.06-1}"
REMOTE_LICENSE="${REMOTE_LICENSE:-27020@kccipangyo1:27020@61.108.38.195}"

target="${1:-simv}"
if [[ $# -gt 0 ]]; then
  shift
fi

shell_quote_words() {
  local word
  for word in "$@"; do
    printf "%q " "$word"
  done
}

quoted_make_args="$(shell_quote_words "$target" "$@")"

ssh -T -o BatchMode=yes -o ConnectTimeout=8 "$REMOTE_HOST" <<REMOTE_SCRIPT
set -e

export VCS_HOME="$REMOTE_VCS_HOME"
export VERDI_HOME="$REMOTE_VERDI_HOME"
export PATH="\$VCS_HOME/bin:\$VERDI_HOME/bin:\$PATH"
export LM_LICENSE_FILE="$REMOTE_LICENSE"
export SNPSLMD_LICENSE_FILE="$REMOTE_LICENSE"

echo "== pedu07 remote context =="
printf 'user=%s\n' "\$(whoami)"
printf 'host=%s\n' "\$(hostname)"
printf 'project=%s\n' "$REMOTE_PROJECT_DIR"
printf 'vcs=%s\n' "\$(command -v vcs || true)"
printf 'make=%s\n' "\$(command -v make || true)"

cd "$REMOTE_PROJECT_DIR"

if [ "$target" = "check" ]; then
  test -f Makefile
  echo "remote project and Makefile found"
  exit 0
fi

echo "== remote make $quoted_make_args =="
make $quoted_make_args
REMOTE_SCRIPT
