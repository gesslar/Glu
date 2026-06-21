/**
 * @file Markdown formatter - A formatter for converting structured
 * documentation data into Markdown format.
 *
 * This formatter takes parsed documentation objects (functions with descriptions,
 * parameters, return types, and examples) and formats them as readable
 * Markdown output.
 *
 * The formatter uses a pipeline approach defined via ActionBuilder and
 * integrates with the BeDoc documentation system.
 *
 * @author gesslar
 * @version 1.0.0
 * @since 1.0.0
 */

import {ActionBuilder, ACTIVITY} from "@gesslar/actioneer"
import {Promised} from "@gesslar/toolkit"

/**
 * Markdown formatter Class - Formats parsed documentation into Markdown.
 *
 * This formatter is designed to work with the structured output from BeDoc
 * parsers, converting function documentation into well-formatted Markdown
 * files with headers, parameter lists, return types, and examples.
 *
 * @class
 */
export default class Markdownformatter {
  /**
   * Printer metadata defining its characteristics and contract.
   *
   * @readonly
   * @type {object}
   * @property {string} kind - The type of action.
   * @property {string} format - The format of the file this formatter emits.
   * @property {string} terms - The contract terms file name.
   */
  static meta = Object.freeze({
    kind: "formatter",
    format: "markdown",
    extension: "md",
    terms: "ref://./bedoc-markdown-formatter.yaml"
  })

  /**
   * Configures the formatter using ActionBuilder's fluent API.
   *
   * This method sets up the formatting pipeline:
   * - Prepare and sort functions
   * - Format each function into Markdown sections (via SPLIT)
   * - Finalize by joining all sections into the output
   *
   * @param {ActionBuilder} builder - The ActionBuilder instance to configure
   * @returns {ActionBuilder} The configured builder instance
   */
  setup = builder => builder
    .do("Format functions", ACTIVITY.SPLIT,
      ctx => ctx, // splitter. just bare, nothing to do here.
      this.#rejoinFormatted, // rejoiner
      new ActionBuilder()
        .do("Format function", this.#formatFunction)
    )
    .do("Finalize", this.#finalize)

  /**
   * Formats a single function's documentation into Markdown.
   *
   * Processes each section of a function (name, description, parameters,
   * return type, and examples) into formatted Markdown text.
   *
   * @param {object} ctx - A parsed function object
   * @param {string} ctx.name - The function name
   * @param {Array<string>} [ctx.description] - Description lines
   * @param {Array<object>} [ctx.param] - Parameter definitions
   * @param {object} [ctx.return] - Return type info
   * @param {Array<string>} [ctx.example] - Example lines
   * @returns {string} Formatted Markdown for this function
   * @private
   */
  #formatFunction = ctx => {
    // TODO: hook(SECTION_LOAD, func)
    const sections = []

    // 1. Print the qualified function name (module.method, not self.method)
    const module = ctx.file?.module
    const method = ctx.signature?.method || ctx.name?.replace(/^self\./, "")
    const qualified = module ? `${module}.${method}` : method
    const parameters = ctx.signature?.parameters?.join(", ") ?? ""

    if(qualified) {
      sections.push(`## ${qualified}`)
      sections.push(`\`function ${qualified}(${parameters})\``)
    }

    // 2. Print the description
    if(ctx.description?.length) {
      // TODO: hook(ENTER, {sectionName: "description", ...})
      const formatted = ctx.description.map(line => line.trim()).join("\n").trim()
      // TODO: hook(EXIT, {sectionName: "description", ...})
      sections.push(formatted)
    }

    // 3. Print the parameters
    if(ctx.param?.length) {
      // TODO: hook(ENTER, {sectionName: "param", ...})
      const params = ctx.param.map(p => {
        let paramName = p.name
        let optional = false
        let defaultValue = null

        // Determine if this is an optional parameter
        const optionalMatch = paramName.match(/^\[(.*)\]$/)
        if(optionalMatch) {
          optional = true
          paramName = optionalMatch[1]
        }

        // Determine if there is a default value
        const defaultMatch = paramName.match(/(.*)=(.*)/)
        if(defaultMatch) {
          paramName = defaultMatch[1]
          defaultValue = defaultMatch[2]
        }

        const optionalAndOrDefault = optional || defaultValue
          ? (() => {
            if(optional && defaultValue)
              return ` (Optional. Default: ${defaultValue})`
            else if(optional)
              return " (Optional)"
            else if(defaultValue)
              return ` (Default: ${defaultValue})`
            else
              throw new Error("Uhm, we seem to have hit a bump.")
          })()
          : ""

        const content = [...(p.content ?? [])]
        while(content.length && (!content.at(0) || !content.at(-1))) {
          if(!content.at(0))
            content.shift()

          if(!content.at(-1))
            content.pop()
        }

        return `* **${paramName}** *${p.type}${optionalAndOrDefault}*` +
          `: ${content.map(c => c.trim()).join(" ")}`
      })
      // TODO: hook(EXIT, {sectionName: "param", ...})

      sections.push(params.join("\n"))
    }

    // 4. Print the return type(s)
    if(ctx.return?.length) {
      // TODO: hook(ENTER, {sectionName: "return", ...})
      const lines = ctx.return.map(ret => {
        const type = Array.isArray(ret.type) ? ret.type.join("|") : ret.type
        const name = ret.name ? ` \`${ret.name}\`` : ""
        const desc = (ret.content ?? []).map(c => c.trim()).filter(Boolean).join(" ")

        return `**${type}**${name}${desc ? ` — ${desc}` : ""}`
      })
      // TODO: hook(EXIT, {sectionName: "return", ...})

      sections.push("### Returns\n\n" + lines.join("\n"))
    }

    // 5. Print the examples
    if(ctx.example?.length) {
      // TODO: hook(ENTER, {sectionName: "example", ...})
      const formatted = "### Example\n\n" + ctx.example.join("\n")
      // TODO: hook(EXIT, {sectionName: "example", ...})

      sections.push(formatted)
    }

    return Object.assign({}, {...ctx, formatted: sections})
  }

  #rejoinFormatted(_, settled) {
    if(Promised.hasRejected(settled))
      Promised.throw(settled)

    const values = Promised.values(settled)
    const formatted = values.map(e => e.formatted)

    formatted.push("") // trailing blank line at the end of the document

    return formatted
  }

  /**
   * Final processing method called after all formatting is complete.
   *
   * Joins the formatted function sections into a single Markdown document.
   *
   * @param {Array<string>} ctx - Array of formatted Markdown strings
   * @returns {string} The complete Markdown output
   * @private
   */
  #finalize = ctx => {
    // TODO: hook(END, ctx)
    return ctx.flat().join("\n\n")
  }
}

/**
 * @todo Reintegrate the following legacy utilities as needed.
 *
 * --- Signature formatting ---
 *
 * Expects a `signature` object on each function with shape:
 *   { access, modifiers: string[], type, name, parameters: string[] }
 *
 * output = `${w.access} ` +
 *   `${w.modifiers.length ? w.modifiers.join(" ") + " " : ""}` +
 *   `*${w.type}* **${w.name}**` +
 *   `(${w.parameters.join(", ")})`
 *
 * --- Word wrap utility ---
 *
 * wrap(str, wrapAt = 80, indentAt = 0) {
 *   const sections = str.split("\n").map(section => {
 *     let parts = section.split(" ")
 *     let inCodeBlock = false
 *     let isStartOfLine = true
 *
 *     if(section[0] === " ")
 *       parts = ["", ...parts]
 *
 *     let running = 0
 *
 *     parts = parts.map(part => {
 *       if(isStartOfLine && /^```(?:\w+)?$/.test(part)) {
 *         inCodeBlock = !inCodeBlock
 *         running += part.length + 1
 *         isStartOfLine = false
 *         return part
 *       }
 *
 *       if(part[0] === "\n") {
 *         running = 0
 *         isStartOfLine = true
 *         return part
 *       }
 *
 *       running += part.length + 1
 *       isStartOfLine = false
 *
 *       if(!inCodeBlock && running >= wrapAt) {
 *         running = part.length + indentAt
 *         isStartOfLine = true
 *         return "\n" + " ".repeat(indentAt) + part
 *       }
 *
 *       return part
 *     })
 *
 *     return parts
 *       .join(" ")
 *       .split("\n")
 *       .map(line => line.trimEnd())
 *       .join("\n")
 *   })
 *
 *   return sections.join("\n")
 * }
 */
