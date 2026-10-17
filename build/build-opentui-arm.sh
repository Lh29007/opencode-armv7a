#!/bin/sh
# Builds libopentui.so (Zig) for 32-bit ARM, with our patches applied on top of anomalyco/opentui v0.5.17.
# Output: out/opentui/arm-linux-musleabihf/libopentui.so
# Needs: git, Python 3 with `pip install ziglang==0.16.0` available (or a zig 0.16 on PATH via ZIG env var).
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
SRC=${OPENTUI_SRC:-$HERE/out/opentui-src}
if [ ! -d "$SRC/.git" ]; then
  GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 --branch v0.5.17 https://github.com/anomalyco/opentui "$SRC"
fi
cd "$SRC"
git checkout -- . 
git apply "$HERE/build/opentui/0001-native-avoid-64bit-atomics-on-32bit-arm.patch"
git apply "$HERE/build/opentui/0002-core-map-android-arm-native-asset.patch"
cd packages/native
sh scripts/prepare-zig-deps.sh
ZIG=${ZIG:-"python3 -m ziglang"}
$ZIG build -Doptimize=ReleaseFast -Dlibrary-target=arm-linux-musleabihf
mkdir -p "$HERE/out/opentui/arm-linux-musleabihf"
cp lib/arm-linux-musleabihf/libopentui.so "$HERE/out/opentui/arm-linux-musleabihf/"
echo "built: $HERE/out/opentui/arm-linux-musleabihf/libopentui.so"
