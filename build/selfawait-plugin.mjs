// Remove `await init_X();` statements inside the body of init_X itself (module self-cycles that deadlock under TLA wrapping)
export function selfAwaitPlugin() {
  return {
    name: "headless:self-await",
    renderChunk(code) {
      let count = 0
      const starts = [...code.matchAll(/var (init_[\w$]+) = __esmMin\(\(async \(\) => \{/g)]
      let out = code
      for (const m of starts.reverse()) {
        const name = m[1]
        const bodyStart = m.index + m[0].length
        const end = out.indexOf("\n}));", bodyStart)
        if (end === -1) continue
        const body = out.slice(bodyStart, end)
        const needle = `await ${name}();`
        if (!body.includes(needle)) continue
        const newBody = body.split(needle).join("")
        count += body.split(needle).length - 1
        out = out.slice(0, bodyStart) + newBody + out.slice(end)
      }
      console.log("[self-await] removed", count)
      return { code: out, map: null }
    },
  }
}
