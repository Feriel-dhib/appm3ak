#!/usr/bin/env bash
# Pré-lancement IDE : crée dart_defines.local.json s’il manque (même détection d’IP que run_dev_lan).
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lan_ip.sh
source "$(dirname "$0")/lan_ip.sh"

if [[ -f dart_defines.local.json ]]; then
  exit 0
fi

ip="$(resolve_lan_ip || true)"
if [[ -z "${ip:-}" ]]; then
  echo "dart_defines.local.json absent et IP LAN non détectée." >&2
  echo "  Créez le fichier : cp dart_defines.local.example.json dart_defines.local.json" >&2
  echo "  puis éditez DEV_LAN_HOST, ou lancez une fois : ./tool/run_dev_lan.sh" >&2
  exit 1
fi

API_PORT="${API_PORT:-3000}"
exec "$(dirname "$0")/write_dart_defines_local.sh" "$ip" "$API_PORT"
