# opencode-armv7a

Headless [OpenCode](https://github.com/anomalyco/opencode) server packaged as a Termux `.deb` for
32-bit ARM devices (`armv7l` / `armv8l`), where the upstream TUI and native modules do not run.

> Made with the help of Claude.

## What this is

- A build recipe that turns the upstream CLI into a Node.js bundle (`opencode.mjs`) and wraps it in a
  Termux package (`opencode_<version>-1_arm.deb`).
- The package runs the **v2 HTTP API server** (`opencode serve`). It does **not** include the terminal UI,
  the web UI, or native terminal/file-watcher modules, because those have no 32-bit ARM builds upstream.

## Status

| Check | Result |
| --- | --- |
| Bundle builds from upstream `2.0.31` on an x64 Linux host | Yes |
| Bundle starts under Node 26.12 (x64) and serves `/api/info`, `/api/session`, `/api/agent`, `/api/config` | Yes (before the last native-guard change) |
| Startup of the native-guard build on x64 | Not re-verified |
| Real device (Termux on armv7 / armv8l) | Not tested yet |
| Model answers through a provider | Not tested (needs an API key and internet) |

Please test on a device and open an issue with the output of
`opencode serve --print-logs --log-level debug` if something fails.

## Requirements

- Build host: Linux x64, [Bun](https://bun.sh) 1.4.2, network access to npm and GitHub.
- Device: Termux with `nodejs` 26.4 or newer (`pkg install nodejs`).

## Build

1. Clone upstream and check out the tested commit:

   ```sh
   git clone https://github.com/anomalyco/opencode
   cd opencode
   git checkout bc5ebf00a4c169ece10f276e6ce02eaf18c326e6   # 2.0.31, the version this recipe targets
   bun install
   ```

   If `bun install` fails on web-only dependencies (`@solidjs/start`, `ghostty-web`), the CLI build is
   not affected and you can continue.

2. Build the `.deb` from this repository:

   ```sh
   git clone https://github.com/Lh29007/opencode-armv7a
   cd opencode-armv7a
   OPENCODE_CLI=/path/to/opencode/packages/cli sh build/build-termux-deb.sh
   ```

   The package is written to `out/opencode_2.0.31-1_arm.deb`.

`build/bundle-headless.ts` applies three build-time fixes on top of upstream:

- `selfns-plugin.mjs`: rewrites self-referential `export * as X from "."` modules into explicit frozen
  namespaces. These create a top-level-await cycle that never resolves under the Node bundle.
- `selfawait-plugin.mjs`: removes `await init_X()` calls inside the body of `init_X`, the same cycle
  from a different angle.
- `nativeguard-plugin.mjs`: wraps eager native `createRequire(...)` calls in `try/catch`, so the
  server still starts on armv8l when an x64 `.node` binary is present in the bundle path.

`build/assets.ts` stages the WebAssembly files (tree-sitter, photon) the bundle needs. Only the
`.wasm` files are packaged; no native binaries.

## Install on Termux

```sh
pkg update && pkg install nodejs
apt install ./opencode_2.0.31-1_arm.deb
OPENCODE_SERVER_PASSWORD='choose-a-password' opencode serve --port 4096
```

Check the server from another Termux session:

```sh
curl -u opencode:choose-a-password http://127.0.0.1:4096/api/info
```

## Using a model with OpenRouter

Set the key in the environment (add it to `~/.bashrc` to keep it):

```sh
export OPENROUTER_API_KEY='your-key'
opencode models     # lists models, needs internet
```

Then create a session and send a prompt through the API:

```sh
SID=$(curl -s -u opencode:choose-a-password -X POST -H 'content-type: application/json' -d '{}' \
  http://127.0.0.1:4096/api/session | sed 's/.*"id":"\([^"]*\)".*/\1/')

curl -s -u opencode:choose-a-password -X POST -H 'content-type: application/json' \
  -d '{"id":"msg_0001","text":"Hello, are you there?"}' \
  http://127.0.0.1:4096/api/session/$SID/prompt

curl -s -u opencode:choose-a-password http://127.0.0.1:4096/api/session/$SID/message
```

Without a configured provider the message list returns `provider.no-route`.

## Limitations

- No TUI and no web UI. The package exposes the API only.
- File watcher and FFF search are disabled by the launcher (`OPENCODE_DISABLE_FILEWATCHER`,
  `OPENCODE_DISABLE_FFF`). Persistent PTY is not available.
- Model lists and provider calls need internet access.
- The build patches upstream at build time and is pinned to `2.0.31`. Upgrading upstream may require
  revisiting the three plugins above.

## Repository layout

```
build/
  bundle-headless.ts        Vite bundle with the build-time fixes
  assets.ts                 Stages wasm/native assets
  build-termux-deb.sh       Produces the .deb
  selfns-plugin.mjs         Fix: self-namespace cycles
  selfawait-plugin.mjs      Fix: self-await deadlocks
  nativeguard-plugin.mjs    Fix: eager native requires
termux/
  opencode                  Launcher installed as $PREFIX/bin/opencode
```

Releases: the built `.deb` is attached to GitHub Releases, not committed.

## License

The OpenCode source is MIT-licensed by its authors (see upstream). The files in this repository
are provided under the same terms unless stated otherwise.
