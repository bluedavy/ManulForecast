#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCTS_DIR="${SYMROOT:-/tmp/ManulForecastProducts}"
INTERMEDIATES_DIR="${OBJROOT:-/tmp/ManulForecastIntermediates}"
APP_PATH="$PRODUCTS_DIR/Debug-iphonesimulator/ManulForecast.app"
BUNDLE_ID="wowtools.ManulForecast"

if [[ -z "${DEVICE_ID:-}" ]]; then
  DEVICE_ID="$(
    xcrun simctl list devices available |
      awk -F '[()]' '/iPhone 17 Pro / { print $2; exit }'
  )"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No available iPhone 17 Pro simulator found. Set DEVICE_ID=<simulator-uuid> and retry." >&2
  exit 1
fi

cd "$ROOT_DIR"

xcodebuild \
  -project ManulForecast.xcodeproj \
  -target ManulForecast \
  -configuration Debug \
  -sdk iphonesimulator \
  SYMROOT="$PRODUCTS_DIR" \
  OBJROOT="$INTERMEDIATES_DIR" \
  build

xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
