#!/usr/bin/env bash
# Verify both patched source identity and the source-built extractor record.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
python3 "$ROOT/scripts/toolchain-identity.py" "${1:-full}"
