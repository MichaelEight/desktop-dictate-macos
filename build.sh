#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="WhisperDictation"
BUNDLE_ID="com.whisper-dictation.app"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

echo "==> Building $APP_NAME (release)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

echo "==> Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

cp "$BUILD_DIR/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS/Info.plist"

if [ -f "$PROJECT_DIR/Resources/WhisperDictation.entitlements" ]; then
    cp "$PROJECT_DIR/Resources/WhisperDictation.entitlements" "$CONTENTS/Resources/"
fi

echo "==> Code signing (ad-hoc)..."
codesign --force --sign - \
    --entitlements "$PROJECT_DIR/Resources/WhisperDictation.entitlements" \
    "$APP_BUNDLE"

# Reset accessibility permission for this bundle ID.
# Ad-hoc signing changes the code signature each build, so macOS sees a
# "different" app even though the bundle ID is the same. The old TCC entry
# becomes stale — the toggle is ON but AXIsProcessTrusted() returns false.
# Resetting forces a clean re-prompt on next launch.
echo "==> Resetting accessibility permission (avoids stale TCC entry)..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

echo "==> Done! Built: $APP_BUNDLE"
echo "    Run with: open $APP_BUNDLE"
