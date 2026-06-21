/**
 * @file Lua library formatter - emits LuaLS "meta" stub files.
 *
 * This formatter takes the same parsed documentation data as the markdown
 * formatter and emits a Lua type-definition stub: every function becomes an
 * empty `function module.method(...) end` body wrapped in `if false then ...
 * end` so the file declares types for the Lua language server without ever
 * executing. These are meant to be dropped into a LuaLS workspace so Mudlet
 * projects consuming Glu get autocomplete and type information.
 *
 * The module/class identity (and an optional @file description) ride along on
 * the parsed functions as a `file` object, surfaced by the parser.
 *
 * @author gesslar
 * @version 1.0.0
 * @since 1.0.0
 */

import {ActionBuilder, ACTIVITY} from "@gesslar/actioneer"
import {Promised} from "@gesslar/toolkit"

const INDENT = "  "
const RULE = "-".repeat(78)

/**
 * Lua library formatter Class - formats parsed documentation into a LuaLS
 * meta stub file.
 *
 * @class
 */
export default class LuaLibraryFormatter {
  /**
   * Formatter metadata defining its characteristics and contract.
   *
   * @readonly
   * @type {object}
   * @property {string} kind - The type of action.
   * @property {string} format - The format of the file this formatter emits.
   * @property {string} extension - The output file extension.
   * @property {string} terms - The contract terms file name.
   */
  static meta = Object.freeze({
    kind: "formatter",
    format: "lua-library",
    extension: "lua",
    terms: "ref://./bedoc-lua-library-formatter.yaml"
  })

  /**
   * Configures the formatter using ActionBuilder's fluent API.
   *
   * @param {ActionBuilder} builder - The ActionBuilder instance to configure
   * @returns {ActionBuilder} The configured builder instance
   */
  setup = builder => builder
    .do("Format stubs", ACTIVITY.SPLIT,
      ctx => ctx, // splitter
      this.#rejoin, // rejoiner
      new ActionBuilder()
        .do("Format stub", this.#formatStub)
    )
    .do("Finalize", this.#finalize)

  /**
   * Formats a single function into an annotated, non-executing stub.
   *
   * @param {object} ctx - A parsed function object
   * @returns {object} The context with a `stub` string attached
   * @private
   */
  #formatStub = ctx => {
    const lines = []
    const module = ctx.file?.module || "_"
    const method = ctx.signature?.method || ctx.name

    // Description block (kept in the new `--- ` style).
    const description = (ctx.description ?? [])
      .map(line => line.trim())
      .join("\n")
      .trim()

    if(description)
      for(const line of description.split("\n"))
        lines.push(`${INDENT}--- ${line}`.trimEnd())

    const hasTags = ctx.param?.length || ctx.return?.length

    if(description && hasTags)
      lines.push(`${INDENT}---`)

    // @param tags — name, type, then freeform description.
    for(const p of ctx.param ?? []) {
      const type = Array.isArray(p.type) ? p.type.join("|") : p.type
      const detail = (p.content ?? []).map(c => c.trim()).filter(Boolean).join(" ")

      lines.push(`${INDENT}---@param ${p.name} ${type}${detail ? ` ${detail}` : ""}`)
    }

    // @return tags — one per returned value. LuaCATS uses the singular
    // `@return` (LuaLS ignores `@returns`). With a name it reads
    // `<type> <name> <desc>`; without one, `# ` delimits the description so
    // LuaLS doesn't mistake its first word for the return name.
    for(const r of ctx.return ?? []) {
      const type = Array.isArray(r.type) ? r.type.join("|") : r.type
      const detail = (r.content ?? []).map(c => c.trim()).filter(Boolean).join(" ")

      let line = `${INDENT}---@return ${type}`

      if(r.name)
        line += ` ${r.name}${detail ? ` ${detail}` : ""}`
      else if(detail)
        line += ` # ${detail}`

      lines.push(line)
    }

    const parameters = ctx.signature?.parameters?.join(", ") ?? ""
    lines.push(`${INDENT}function ${module}.${method}(${parameters}) end`)

    return Object.assign({}, ctx, {stub: lines.join("\n")})
  }

  #rejoin(_, settled) {
    if(Promised.hasRejected(settled))
      Promised.throw(settled)

    return Promised.values(settled)
  }

  /**
   * Wraps the formatted stubs in the LuaLS meta header/footer.
   *
   * @param {Array<object>} ctx - Array of formatted function objects
   * @returns {string} The complete Lua stub file
   * @private
   */
  #finalize = ctx => {
    const functions = ctx.flat()

    if(!functions.length)
      return ""

    const {module, class: className, description} = functions[0].file ?? {}
    const name = className || "Unknown"

    const header = [
      `---@meta ${name}`,
      "",
      RULE,
      `-- ${name}`,
      RULE,
      "",
    ]

    if(description) {
      for(const line of description.split("\n"))
        header.push(`--- ${line}`.trimEnd())
    }

    header.push(`---@class ${name}`)
    header.push(`${module || "_"} = {}`)
    header.push("")
    header.push("if false then -- ensure that functions do not get defined")

    const body = functions.map(f => f.stub).join("\n\n")

    return `${header.join("\n")}\n${body}\nend\n`
  }
}
