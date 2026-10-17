// Replace self-referential `export * as NAME from "."` (or "./<self>") with an explicit frozen namespace
export function selfNamespacePlugin() {
  return {
    name: "headless:self-namespace",
    enforce: "pre",
    transform(code, id) {
      const clean = id.split("?")[0].replaceAll("\\", "/")
      if (!/\.(ts|tsx)$/.test(clean)) return
      const base = clean.split("/").pop().replace(/\.(ts|tsx)$/, "")
      const m = code.match(/^export \* as (\w+) from "(\.|\.\/[\w-]+)";?[ \t]*$/m)
      if (!m) return
      const spec = m[2]
      const selfOk = spec === "." ? base === "index" : spec === `./${base}`
      if (!selfOk) return
      const names = [...code.matchAll(/^export (?:const|let|var|function|async function|class) (\w+)/gm)].map((x) => x[1])
      const out = code.replace(m[0], "") + `\nexport const ${m[1]} = Object.freeze({ ${names.join(", ")} })\n`
      return { code: out, map: null }
    },
  }
}
