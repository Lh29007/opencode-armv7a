// Builds the headless OpenCode server bundle (no TUI, no native modules) from anomalyco/opencode.
// Usage: OPENCODE_CLI=/path/to/opencode/packages/cli bun build/bundle-headless.ts
import { createRequire } from "node:module"
import path from "node:path"
import { selfNamespacePlugin } from "./selfns-plugin.mjs"
import { selfAwaitPlugin } from "./selfawait-plugin.mjs"
import { nativeGuardPlugin } from "./nativeguard-plugin.mjs"

const CLI = path.resolve(process.env.OPENCODE_CLI ?? "/home/claude/anomalyco/opencode/packages/cli")
process.chdir(CLI)

const req = createRequire(path.join(CLI, "package.json"))
const { build } = await import(req.resolve("vite"))
const { mainConfig } = await import(path.join(CLI, "vite.node.config.ts"))
const { nodeTarget } = await import(path.join(CLI, "src/node/target.ts"))

const cfg = mainConfig({
  version: "2.0.31",
  channel: "latest",
  highlights: undefined,
  assetHash: "dev",
  target: nodeTarget("linux", "x64"),
}) as any
cfg.plugins.unshift(selfNamespacePlugin())   // fix: export * as X from "." self-cycles
cfg.plugins.push(selfAwaitPlugin())          // fix: init_X awaiting itself deadlocks under TLA
cfg.plugins.push(nativeGuardPlugin())        // fix: eager native requires abort startup on armv8l
cfg.build.minify = false
cfg.build.outDir = "dist-headless"
await build(cfg)
console.log("headless bundle ok:", path.join(CLI, "dist-headless/opencode.mjs"))
