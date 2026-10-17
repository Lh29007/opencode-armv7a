// Native addons that are loaded eagerly at module evaluation (not lazily) would abort startup on armv8l,
// where the x64 .node binaries are absent. Wrap such top-level requires in try/catch so the server
// still starts; the feature that needs the addon (PTY) fails only when it is actually used.
export function nativeGuardPlugin() {
  return {
    name: "headless:native-guard",
    renderChunk(code) {
      const re = /^const (\w+) = createRequire\(import\.meta\.url\)\((process\.env\.\w+ \?\? "[^"]+")\);$/gm
      let count = 0
      const out = code.replace(re, (_m, name, arg) => {
        count++
        return `let ${name}; try { ${name} = createRequire(import.meta.url)(${arg}) } catch (e) { ${name} = undefined }`
      })
      console.log("[native-guard] guarded eager requires:", count)
      return { code: out, map: null }
    },
  }
}
