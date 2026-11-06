#!/bin/bash
# Builds build/Eyedropper.app as a universal binary (Apple silicon + Intel).
#   ./build.sh            build only
#   ./build.sh --install  also copy to /Applications and launch
#   ./build.sh --zip      also make build/Eyedropper.zip for a GitHub release
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Eyedropper.app"
BIN="$APP/Contents/MacOS/Eyedropper"

rm -rf "$APP" build/obj
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/obj

for ARCH in arm64 x86_64; do
  swiftc -O -swift-version 5 \
    -target "$ARCH-apple-macos14.0" \
    -o "build/obj/Eyedropper-$ARCH" \
    Sources/*.swift
done
lipo -create build/obj/Eyedropper-arm64 build/obj/Eyedropper-x86_64 -output "$BIN"
rm -rf build/obj

cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP" >/dev/null
echo "Built $APP ($(lipo -archs "$BIN"))"

case "${1:-}" in
  --install)
    pkill -x Eyedropper 2>/dev/null || true
    rm -rf /Applications/Eyedropper.app
    cp -R "$APP" /Applications/
    open /Applications/Eyedropper.app
    echo "Installed to /Applications/Eyedropper.app"
    ;;
  --zip)
    rm -f build/Eyedropper.zip
    ditto -c -k --keepParent "$APP" build/Eyedropper.zip
    echo "Zipped build/Eyedropper.zip"
    ;;
esac
