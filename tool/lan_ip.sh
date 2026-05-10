#!/usr/bin/env bash
# Première IPv4 locale utile (macOS). Affiche sur stdout ; code 1 si aucune.
resolve_lan_ip() {
  if [[ "$(uname -s)" != "Darwin" ]]; then return 1; fi
  local ip
  for dev in en0 en1; do
    ip="$(ipconfig getifaddr "$dev" 2>/dev/null || true)"
    if [[ -n "$ip" ]]; then echo "$ip"; return 0; fi
  done
  ifconfig 2>/dev/null | awk '/inet / && $2 !~ /^127\./ { print $2; exit }' || true
}
