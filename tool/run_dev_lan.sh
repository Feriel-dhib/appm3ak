#!/usr/bin/env bash
# Lancement Flutter avec l’API sur le Mac (iPhone / simulateur sur le même réseau).
#
# Prérequis côté backend : écouter sur 0.0.0.0:3000 (pas seulement 127.0.0.1).
#
# Connexion appareil (Flutter) :
#   - auto (défaut) : « attached » si Flutter voit un iPhone en USB ; sinon « both » (sans fil inclus).
#     Forcer « attached » seul masque l’iPhone si l’USB n’est pas reconnu par Xcode / Flutter.
#   - Forcer : FLUTTER_DEVICE_CONNECTION=attached|both
# Timeout découverte : FLUTTER_DEVICE_TIMEOUT=120 (défaut 180 si mode both auto / explicite).
#
# Écrit aussi dart_defines.local.json pour que Run (Cursor) avec --dart-define-from-file
# utilise la même IP / port que ce script.
#
# Usage :
#   ./tool/run_dev_lan.sh
#   ./tool/run_dev_lan.sh -d "Rafaelle Wolf"
#   DEV_LAN_HOST=192.168.1.10 ./tool/run_dev_lan.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lan_ip.sh
source "$(dirname "$0")/lan_ip.sh"

# Consomme les options locales du script (ex. --host) avant de déléguer à flutter run.
forward_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      if [[ $# -lt 2 ]]; then
        echo "Option --host requiert une valeur, ex. --host 192.168.1.10" >&2
        exit 2
      fi
      DEV_LAN_HOST="$2"
      shift 2
      ;;
    --host=*)
      DEV_LAN_HOST="${1#--host=}"
      shift
      ;;
    --api-port)
      if [[ $# -lt 2 ]]; then
        echo "Option --api-port requiert une valeur, ex. --api-port 3000" >&2
        exit 2
      fi
      API_PORT="$2"
      shift 2
      ;;
    --api-port=*)
      API_PORT="${1#--api-port=}"
      shift
      ;;
    *)
      forward_args+=("$1")
      shift
      ;;
  esac
done

# Renvoie « attached » si au moins un iPhone / iPad physique est listé en USB uniquement, sinon « both ».
resolve_device_connection() {
  if [[ -n "${FLUTTER_DEVICE_CONNECTION:-}" ]]; then
    printf '%s' "$FLUTTER_DEVICE_CONNECTION"
    return
  fi
  local json
  json="$(flutter devices --machine --device-connection=attached 2>/dev/null || true)"
  if printf '%s' "${json:-[]}" | python3 -c "
import json, sys
raw = sys.stdin.read().strip() or '[]'
try:
    d = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(1)
ok = any(x.get('targetPlatform') == 'ios' and not x.get('emulator', False) for x in d)
sys.exit(0 if ok else 1)
"; then
    printf 'attached'
  else
    printf 'both'
  fi
}

if [[ -z "${DEV_LAN_HOST:-}" ]]; then
  DEV_LAN_HOST="$(resolve_lan_ip || true)"
fi

if [[ -z "${DEV_LAN_HOST:-}" ]]; then
  echo "Impossible de détecter l’IP du Mac. Définissez :" >&2
  echo "  export DEV_LAN_HOST=192.168.x.x   # ou 172.20.10.x (partage de connexion)" >&2
  exit 1
fi

API_PORT="${API_PORT:-3000}"
echo "→ API: http://${DEV_LAN_HOST}:${API_PORT}" >&2
echo "→ Vérifiez que le serveur écoute sur 0.0.0.0:${API_PORT}" >&2
"$(dirname "$0")/write_dart_defines_local.sh" "$DEV_LAN_HOST" "$API_PORT"

DEVICE_CONN="$(resolve_device_connection)"
if [[ -z "${FLUTTER_DEVICE_CONNECTION:-}" && "$DEVICE_CONN" == "both" ]]; then
  echo "→ Flutter ne liste aucun iPhone en USB seul (--device-connection=attached). Passage en mode « both » (sans fil autorisé)." >&2
  echo "  Pour retrouver l’USB : câble données, iPhone déverrouillé, « Faire confiance à cet ordinateur », Xcode → Window → Devices and Simulators → décocher « Connect via network » pour l’appareil." >&2
fi
if [[ -n "${FLUTTER_DEVICE_TIMEOUT:-}" ]]; then
  DEVICE_TO="$FLUTTER_DEVICE_TIMEOUT"
elif [[ "$DEVICE_CONN" == "both" ]]; then
  DEVICE_TO=180
else
  DEVICE_TO=120
fi

extra_device_args=()
if ! printf '%s\0' "$@" | grep -qzF -- '--device-connection'; then
  extra_device_args+=(--device-connection="$DEVICE_CONN")
fi
if ! printf '%s\0' "$@" | grep -qzF -- '--device-timeout'; then
  extra_device_args+=(--device-timeout="$DEVICE_TO")
fi

exec flutter run \
  "${extra_device_args[@]}" \
  --dart-define-from-file=dart_defines.local.json \
  "${forward_args[@]}"
