#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v curl >/dev/null || { echo 'curl is required to bundle the web fonts.' >&2; exit 1; }
mkdir -p assets/fonts
tracker_font_base='https://raw.githubusercontent.com/google/fonts/main/ofl'
fetch_font() {
  local tracker_font_url="$1" tracker_font_file="$2"
  if [[ -s "assets/fonts/$tracker_font_file" ]]; then return; fi
  curl --fail --location --retry 3 --connect-timeout 15 "$tracker_font_url" -o "assets/fonts/$tracker_font_file.tmp"
  mv "assets/fonts/$tracker_font_file.tmp" "assets/fonts/$tracker_font_file"
}
fetch_font "$tracker_font_base/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf" 'PlusJakartaSans.ttf'
fetch_font "$tracker_font_base/plusjakartasans/OFL.txt" 'PlusJakartaSans-OFL.txt'
fetch_font "$tracker_font_base/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf" 'JetBrainsMono.ttf'
fetch_font "$tracker_font_base/jetbrainsmono/OFL.txt" 'JetBrainsMono-OFL.txt'
