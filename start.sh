#!/usr/bin/env bash
#
# Start ComfyUI.
#
#   ./start.sh                  # http://127.0.0.1:8188
#   ./start.sh --port 8288      # extra args are passed through to main.py
#   ./start.sh --cpu            # fall back to CPU if MPS misbehaves
#
set -euo pipefail

cd "$(dirname "$0")"

PYTHON="venv/bin/python"

if [ ! -x "$PYTHON" ]; then
    echo "error: no virtualenv at ./venv" >&2
    echo "  python3 -m venv venv && venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

# This drive is not APFS/HFS+, so macOS stores extended attributes in AppleDouble
# "._*" sidecar files. transformers reads every entry in its models/ directory as
# UTF-8 at import time and crashes on those binary sidecars, so sweep them first.
find venv/lib/python*/site-packages/transformers -name '._*' -delete 2>/dev/null || true

if ! "$PYTHON" -c "import torch" 2>/dev/null; then
    echo "error: torch is not installed in ./venv" >&2
    echo "  venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

# Let MPS spill to system RAM instead of erroring out on large models.
export PYTORCH_ENABLE_MPS_FALLBACK=1

exec "$PYTHON" main.py "$@"
