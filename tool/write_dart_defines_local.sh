#!/usr/bin/env bash
# Écrit [repo]/dart_defines.local.json pour --dart-define-from-file (Cursor / VS Code, même logique que run_dev_lan).
# Usage : ./tool/write_dart_defines_local.sh <DEV_LAN_HOST> [API_PORT]
set -euo pipefail
cd "$(dirname "$0")/.."
host="${1:?DEV_LAN_HOST requis}"
port="${2:-3000}"
python3 -c "import json,sys; json.dump({'DEV_LAN_HOST':sys.argv[1],'API_PORT':sys.argv[2]},open('dart_defines.local.json','w'),indent=2)" "$host" "$port"
echo "→ dart_defines.local.json : DEV_LAN_HOST=$host API_PORT=$port" >&2
