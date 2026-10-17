#!/bin/sh
# Builds @opentui/core (JS) from the patched opentui source and installs it into the opencode checkout,
# replacing the npm-published package that the CLI bundle would otherwise use.
# Usage: OPENCODE_REPO=/path/to/opencode OPENTUI_SRC=/path/to/opentui-v0.5.17 sh build/install-patched-core.sh
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
OPENCODE_REPO=${OPENCODE_REPO:-/home/claude/anomalyco/opencode}
OPENTUI_SRC=${OPENTUI_SRC:-$HERE/out/opentui-src}
cd "$OPENTUI_SRC" && git apply --check -R "$HERE/build/opentui/0002-core-map-android-arm-native-asset.patch" 2>/dev/null || git apply "$HERE/build/opentui/0002-core-map-android-arm-native-asset.patch"
bun install
cd packages/core && bun scripts/build.ts --lib
DEST=$(ls -d "$OPENCODE_REPO"/node_modules/.bun/@opentui+core@*/node_modules/@opentui/core | head -1)
cp -r "$DEST" "$HERE/out/core-npm-backup" 2>/dev/null || true
cp -r dist/. "$DEST/"
echo "patched @opentui/core installed in: $DEST"
