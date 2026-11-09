#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
"$ROOT/scripts/check-generic.sh"
"$ROOT/scripts/check-concrete.sh" "$@"
