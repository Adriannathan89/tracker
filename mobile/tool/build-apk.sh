#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v flutter >/dev/null || { echo 'Install Flutter 3.35.7 and Android SDK first.' >&2; exit 1; }
tracker_api_url="${TRACKER_API_URL:-https://tracker.adrianportofolio.my.id/api/}"
case "$tracker_api_url" in
  https://*) ;;
  *) echo 'Release APK requires an HTTPS TRACKER_API_URL.' >&2; exit 1 ;;
esac
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --release --dart-define="TRACKER_API_URL=$tracker_api_url" "$@"
echo 'APK output: mobile/build/app/outputs/flutter-apk/'
