#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="markiiupMac"
APP_DISPLAY_NAME="markiiup"
BUNDLE_ID="com.mtdmo.markiiupMac"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$APP_RESOURCES/markiiupAppIcon.icns"
BRAND_IMAGE="$APP_RESOURCES/markiiup_cat.png"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

echo "Building $APP_NAME..."
swift build -c debug --product "$APP_NAME"
BUILD_BINARY="$(swift build -c debug --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

swift "$ROOT_DIR/script/generate_app_icon.swift" "$ROOT_DIR/markiiup_cat.png" "$APP_ICON"
cp "$ROOT_DIR/markiiup_cat.png" "$BRAND_IMAGE"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>markiiupAppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  echo "Launching $APP_BUNDLE..."
  /usr/bin/open -n "$APP_BUNDLE"
}

open_app_with_document() {
  local document_path="$1"
  echo "Launching $APP_BUNDLE with $document_path..."
  /usr/bin/open -n -a "$APP_BUNDLE" "$document_path"
}

case "$MODE" in
  run)
    open_app
    echo "Launch request sent."
    ;;
  --sample|sample)
    open_app_with_document "$ROOT_DIR/examplefile.md"
    echo "Sample launch request sent."
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "$APP_NAME is running."
    ;;
  *)
    echo "usage: $0 [run|--sample|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
