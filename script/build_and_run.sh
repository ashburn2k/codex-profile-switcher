#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CodexConfigSwitcher"
BUNDLE_ID="app.codexconfigswitcher.CodexConfigSwitcher"
SCHEME="CodexConfigSwitcher"
CONFIGURATION="Debug"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/CodexConfigSwitcher.xcodeproj"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
APP_BUNDLE="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

clean_app_metadata() {
  rm -rf "$APP_BUNDLE/Contents/_CodeSignature"
  xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true
  find "$APP_BUNDLE" -exec xattr -d com.apple.FinderInfo {} \; >/dev/null 2>&1 || true
}

sign_app() {
  if /usr/bin/codesign --force --deep --sign - --timestamp=none "$APP_BUNDLE"; then
    return
  fi

  clean_app_metadata
  if /usr/bin/codesign --force --deep --sign - --timestamp=none "$APP_BUNDLE"; then
    return
  fi

  clean_app_metadata
  echo "warning: codesign skipped; launching unsigned debug app" >&2
}

build_app() {
  cd "$ROOT_DIR"

  if [[ -d "$ROOT_DIR/CodexConfigSwitcher/Assets.xcassets" ]]; then
    xattr -cr "$ROOT_DIR/CodexConfigSwitcher/Assets.xcassets"
  fi

  if command -v xcodegen >/dev/null 2>&1 && [[ -f "$ROOT_DIR/project.yml" ]]; then
    xcodegen generate
  fi

  COPYFILE_DISABLE=1 "$XCODEBUILD" \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    build

  clean_app_metadata
  sign_app
}

stop_app() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
  sleep 0.5
  /usr/bin/osascript -e "tell application \"$APP_NAME\" to activate" >/dev/null 2>&1 || true
}

stop_app
build_app

case "$MODE" in
  run)
    open_app
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
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
