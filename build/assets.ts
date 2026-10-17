// Stages the wasm/native assets the bundle expects under dist-node/assets.
import path from "node:path"
import { mkdir, writeFile } from "node:fs/promises"

const CLI = path.resolve(process.env.OPENCODE_CLI ?? "/home/claude/anomalyco/opencode/packages/cli")
process.chdir(CLI)
const { collectNodeAssets, copyNodeAssets } = await import(path.join(CLI, "script/node-assets.ts"))
const { nodeTarget } = await import(path.join(CLI, "src/node/target.ts"))
const assets = await collectNodeAssets(nodeTarget("linux", "x64"))
await copyNodeAssets(assets)
await mkdir("dist-node/assets", { recursive: true })
await writeFile("dist-node/assets/app-archive.bin", new Uint8Array())
console.log("staged assets:", assets.length)
