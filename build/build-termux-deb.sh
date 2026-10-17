#!/bin/sh
# Builds opencode_<version>-1_arm.deb for Termux (arm / armv8l) from an anomalyco/opencode checkout.
# Usage: OPENCODE_CLI=/path/to/opencode/packages/cli sh build/build-termux-deb.sh
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
CLI=${OPENCODE_CLI:-/home/claude/anomalyco/opencode/packages/cli}
VERSION=2.0.31
export OPENCODE_CLI="$CLI"
cd "$CLI"
bun "$HERE/build/bundle-headless.ts"
bun "$HERE/build/assets.ts"
R="$HERE/out/deb-root"; P="$R/data/data/com.termux/files/usr"
rm -rf "$R"; mkdir -p "$P/bin" "$P/lib/opencode" "$R/DEBIAN"
cp "$CLI/dist-headless/opencode.mjs" "$P/lib/opencode/"
A="$CLI/dist-node/assets"
for f in @silvia-odwyer/photon-node/photon_rs_bg.wasm web-tree-sitter/tree-sitter.wasm \
         tree-sitter-bash/tree-sitter-bash.wasm tree-sitter-powershell/tree-sitter-powershell.wasm; do
  mkdir -p "$P/lib/opencode/assets/$(dirname "$f")"
  cp "$A/$f" "$P/lib/opencode/assets/$f"
done
: > "$P/lib/opencode/assets/app-archive.bin"
cp "$HERE/termux/opencode" "$P/bin/opencode"; chmod 755 "$P/bin/opencode"
SIZE=$(du -sk "$R/data" | cut -f1)
cat > "$R/DEBIAN/control" <<CTRL
Package: opencode
Version: $VERSION-1
Architecture: arm
Maintainer: local-build <local@localhost>
Installed-Size: $SIZE
Depends: nodejs (>= 26.4.0)
Section: devel
Priority: optional
Homepage: https://github.com/anomalyco/opencode
Description: OpenCode headless server (v2 API) for Termux armv7/armv8l
 Node bundle of anomalyco/opencode $VERSION without TUI and without native modules.
CTRL
mkdir -p "$HERE/out"
dpkg-deb --root-owner-group -Zxz --build "$R" "$HERE/out/opencode_${VERSION}-1_arm.deb"
echo "built: $HERE/out/opencode_${VERSION}-1_arm.deb"
