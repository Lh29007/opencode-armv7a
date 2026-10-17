#!/bin/sh
# Packages the experimental TUI + server for a Debian armhf proot.
# Inputs (env):
#   NODE_BIN   path to the Node 26 armv7 binary built from source (out/Release/node)
#   OPENCODE_CLI  path to the opencode packages/cli checkout (must contain dist-headless/opencode.mjs)
#   OPENTUI_LIB   path to the glibc libopentui.so built by build/build-opentui-arm.sh
# Output: out/opencode-proot-armhf.tar.gz
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
: "${NODE_BIN:?set NODE_BIN to the armv7 node 26 binary}"
: "${OPENCODE_CLI:?set OPENCODE_CLI to the opencode packages/cli checkout}"
: "${OPENTUI_LIB:?set OPENTUI_LIB to the glibc libopentui.so}"
T="$HERE/out/proot-root/opencode-proot-armhf"
rm -rf "$HERE/out/proot-root"; mkdir -p "$T/bin" "$T/lib/opencode/assets/@silvia-odwyer/photon-node" \
  "$T/lib/opencode/assets/web-tree-sitter" "$T/lib/opencode/assets/tree-sitter-bash" \
  "$T/lib/opencode/assets/tree-sitter-powershell" "$T/lib/opencode/assets/@opentui/core-linux-arm"
cp "$NODE_BIN" "$T/bin/node"; chmod 755 "$T/bin/node"
cp "$OPENCODE_CLI/dist-headless/opencode.mjs" "$T/lib/opencode/"
A="$OPENCODE_CLI/dist-node/assets"
cp "$A/@silvia-odwyer/photon-node/photon_rs_bg.wasm" "$T/lib/opencode/assets/@silvia-odwyer/photon-node/"
cp "$A/web-tree-sitter/tree-sitter.wasm" "$T/lib/opencode/assets/web-tree-sitter/"
cp "$A/tree-sitter-bash/tree-sitter-bash.wasm" "$T/lib/opencode/assets/tree-sitter-bash/"
cp "$A/tree-sitter-powershell/tree-sitter-powershell.wasm" "$T/lib/opencode/assets/tree-sitter-powershell/"
cp "$OPENTUI_LIB" "$T/lib/opencode/assets/@opentui/core-linux-arm/libopentui.so"
: > "$T/lib/opencode/assets/app-archive.bin"
cat > "$T/bin/opencode" <<'LAUNCH'
#!/bin/sh
# Experimental TUI/server launcher for Debian armhf proot.
HERE=$(cd "$(dirname "$0")/.." && pwd)
export OPENCODE_DISABLE_FILEWATCHER="${OPENCODE_DISABLE_FILEWATCHER:-1}"
export OPENCODE_DISABLE_FFF="${OPENCODE_DISABLE_FFF:-1}"
exec "$HERE/bin/node" --experimental-ffi --use-system-ca --disable-warning=ExperimentalWarning "$HERE/lib/opencode/opencode.mjs" "$@"
LAUNCH
chmod 755 "$T/bin/opencode"
cat > "$T/README.txt" <<'TXT'
opencode (experimental TUI) for Debian armhf proot

Inside the proot:
  apt install -y libstdc++6 ca-certificates
  tar xzf opencode-proot-armhf.tar.gz -C /opt
  ln -s /opt/opencode-proot-armhf/bin/opencode /usr/local/bin/opencode
  opencode            # TUI
  opencode serve --port 4096   # API only
TXT
mkdir -p "$HERE/out"
tar -C "$HERE/out/proot-root" -czf "$HERE/out/opencode-proot-armhf.tar.gz" opencode-proot-armhf
echo "built: $HERE/out/opencode-proot-armhf.tar.gz"
