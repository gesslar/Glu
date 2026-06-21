/**
 * @file Lua Parser - A parser for extracting documentation from Lua files.
 *
 * This parser specifically handles Lua function documentation comments and
 * extracts structured information including descriptions, parameters, return
 * types, and examples.
 *
 * The parser uses a contract-based approach defined in bedoc-lua-parser.yaml
 * and integrates with the BeDoc documentation system through ActionBuilder.
 *
 * @author gesslar
 * @version 1.0.0
 * @since 1.0.0
 */

import {ActionBuilder, ACTIVITY} from "@gesslar/actioneer"
import {Collection} from "@gesslar/toolkit"

/**
 * Lua Parser Class - Parses Lua files to extract function documentation.
 *
 * This parser is designed to work with Lua source files, extracting LDoc
 * comments and function signatures. It identifies functions with their scope,
 * delimiter, method name, parameters, and associated documentation.
 *
 * @class
 */
export default class LuaParser {
  /**
   * Parser metadata defining its characteristics and contract.
   *
   * @readonly
   * @type {object}
   * @property {string} kind - The type of action.
   * @property {string} input - The input file type this parser handles.
   * @property {string} terms - The contract file name.
   */
  static meta = Object.freeze({
    kind: "parser",
    input: "lua",
    terms: "ref://./bedoc-lua-parser.yaml"
  })

  /**
   * Configures the parser using ActionBuilder's fluent API.
   *
   * This method sets up the parsing structure and extraction methods for Lua
   * documentation.
   *
   * It defines:
   * - Comment block structure (LDoc-style --- comments)
   * - Function signature patterns with Lua-specific scope/method syntax
   * - Extraction methods for descriptions, tags, and return values
   *
   * @param {ActionBuilder} builder - The ActionBuilder instance to configure
   * @returns {ActionBuilder} The configured builder instance
   * @example
   * // Lua function patterns matched:
   * // function MyModule.my_function(arg1, arg2)
   * // function MyModule:my_method(arg1, arg2)
   * @see ActionBuilder
   */
  setup = builder => builder
    .do("Extract blocks", this.#extractBlocks)
    .do("Process functions", ACTIVITY.SPLIT,
      ctx => ctx, // splitter
      ctx => ctx, // rejoiner
      new ActionBuilder()
        .do("Extract signature", this.#extractSignature)
        .do("Extract description", this.#extractDescription)
        .do("Extract tags", this.#extractTags)
    )
    .done(this.#finally)

  #extractBlocks = ctx => {
    // Capture the module/class identity from the Glu.glass.register({...}) head.
    // The library formatter needs these for the ---@class / `module = {}` lines;
    // the markdown formatter simply ignores them.
    this.#meta = {
      module: ctx.match(/\bname\s*=\s*["']([^"']+)["']/)?.[1] ?? "",
      class: ctx.match(/\bclass_name\s*=\s*["']([^"']+)["']/)?.[1] ?? "",
      description: ctx.match(/---\s?@file\b[ \t]*(?<text>.*)/)?.groups?.text?.trim() ?? "",
    }

    const result = []
    const lines = ctx.split(/\r?\n/)

    while(lines.length) {
      const block = {}

      // Find the start of a comment block
      const startIndex = lines.findIndex(line =>
        this.#regexes.get("comment-start").test(line.trim())
      )
      if(startIndex < 0)
        break

      // Remove everything before the comment block
      lines.splice(0, startIndex)

      // Collect all consecutive comment lines
      const commentLines = []
      while(lines.length && this.#regexes.get("comment-start").test(lines[0].trim())) {
        commentLines.push(lines.shift())
      }

      block.lines = commentLines

      // Look ahead for a function definition, stopping at the next comment start
      const funcIndex = lines.findIndex(line => {
        const trimmed = line.trim()

        return this.#regexes.get("function").test(trimmed) ||
               this.#regexes.get("comment-start").test(trimmed)
      })

      if(funcIndex >= 0 && this.#regexes.get("function").test(lines[funcIndex].trim())) {
        block.function = this.#regexes.get("function").exec(lines[funcIndex].trim())
        lines.splice(0, funcIndex + 1)
        result.push(block)
      } else if(funcIndex >= 0) {
        // Hit another comment start before a function — discard this block
        lines.splice(0, funcIndex)
      }
      // else: no more lines, block has no function — discard
    }

    return result
  }

  #extractSignature = ctx => {
    const {function: func} = ctx
    if(!func?.groups?.name)
      return ctx

    const groups = func.groups
    const signature = {
      name: groups.name,
      scope: groups.scope ?? null,
      delimiter: groups.delimiter ?? null,
      method: groups.method,
      modifiers: [],
      access: "",
      parameters: groups.parms?.split(",").map(p => p.trim()) ?? []
    }

    return Object.assign(ctx, {signature})
  }

  /**
   * Extracts the description section from LDoc-style comment lines.
   *
   * Processes comment lines to extract the main description text that appears
   * before any @tag declarations.
   *
   * @param {object} ctx - The block context being processed
   * @returns {object} The context with description added
   * @private
   */
  #extractDescription = ctx => {
    const {lines} = ctx

    const comment = this.#regexes.get("comment-content")
    const tagId = this.#regexes.get("tag-id")

    const description = []
    Object.assign(ctx, {description})

    while(lines.length > 0) {
      const line = lines[0].trim()

      if(!comment.test(line))
        break

      if(tagId.test(line))
        break

      lines.shift()
      const {content} = comment.exec(line)?.groups ?? {}
      description.push(content ?? "")
    }

    return ctx
  }

  /**
   * Extracts LDoc-style tags from comment lines.
   *
   * Handles @param, @return/@returns, @example, and @name tags.
   *
   * @param {object} ctx - The block context being processed
   * @returns {object} The context with tags added
   * @private
   */
  #extractTags = ctx => {
    const {lines} = ctx

    const comment = this.#regexes.get("comment-content")
    const tagPattern = this.#regexes.get("tag")
    const paramContent = this.#regexes.get("param-content")
    const returnContent = this.#regexes.get("return-content")
    const tagId = this.#regexes.get("tag-id")

    const extractedTags = {}
    Object.assign(ctx, {tag: extractedTags})

    while(lines.length > 0) {
      const line = lines.shift()
      const lineTrimmed = line.trim()

      if(!comment.test(lineTrimmed))
        continue

      const tagMatch = tagPattern.exec(lineTrimmed)
      if(!tagMatch)
        continue

      const {tag, content} = tagMatch.groups
      const normalizedTag = tag === "returns" ? "return" : tag

      if(normalizedTag === "return") {
        const retMatch = returnContent.exec(content)
        if(retMatch) {
          const {type, rest} = retMatch.groups
          const entry = {type, content: []}
          const remainder = rest ?? ""
          const hashMatch = remainder.match(/^#\s*(?<desc>.*)$/)

          if(hashMatch) {
            // ---@return <type> # <description>  (explicitly no name)
            entry.content = hashMatch.groups.desc ? [hashMatch.groups.desc] : []
          } else if(remainder) {
            // ---@return <type> <name> <description>
            const named = remainder.match(/^(?<name>\S+)(?:\s+(?<desc>.*))?$/)
            entry.name = named.groups.name
            entry.content = named.groups.desc ? [named.groups.desc] : []
          }

          if(!extractedTags["return"])
            extractedTags["return"] = []

          extractedTags["return"].push(entry)
        }
      } else if(normalizedTag === "name") {
        if(content)
          extractedTags["name"] = content
      } else if(normalizedTag === "example") {
        const exampleLines = content ? [content] : []

        while(lines.length > 0) {
          const next = lines[0].trim()
          if(!comment.test(next) || tagId.test(next))
            break

          lines.shift()
          const {content: lineContent} = comment.exec(next)?.groups ?? {}
          exampleLines.push(lineContent ?? "")
        }

        extractedTags["example"] = exampleLines
      } else if(normalizedTag === "param") {
        const paramMatch = paramContent.exec(content)
        if(paramMatch) {
          const {name, type, content: desc} = paramMatch.groups
          const paramEntry = {type, name, content: desc ? [desc] : []}

          if(!extractedTags["param"])
            extractedTags["param"] = []

          extractedTags["param"].push(paramEntry)

          while(lines.length > 0) {
            const next = lines[0].trim()
            if(!comment.test(next) || tagId.test(next))
              break

            lines.shift()
            const {content: lineContent} = comment.exec(next)?.groups ?? {}
            paramEntry.content.push(lineContent ?? "")
          }
        }
      }
    }

    return ctx
  }

  /**
   * Final processing method called after all extraction is complete.
   *
   * @param {Array<object>} ctx - Array of extracted block data
   * @returns {Promise<object>} The transformation results.
   * @private
   */
  #finally = async ctx => {
    const functions = await Collection.asyncMap(ctx, async func => {
      const result = {
        name: func.function.groups.name,
        file: this.#meta,
        description: func.description,
        signature: {
          ...func.signature,
          type: (func.tag?.return ?? []).map(r => r.type).join(", "),
        },
      }

      const tags = func.tag ?? {}

      if(tags.param)
        result.param = tags.param
          .map(({type, name, content}) => ({type, name, content}))

      if(tags.return)
        result.return = tags.return

      if(tags.example)
        result.example = tags.example

      return result
    })

    return {functions}
  }

  // Module/class identity captured per-file from the register({...}) head.
  #meta = null

  // HERE BE DRAGONS! YOU DONE BEEN WARNED, FUGGAH!
  #regexes = new Map([
    ["comment-start", /^\s*---\s?.*$/],
    ["comment-content", /^\s*---\s?(?<content>.*)$/],
    ["blank", /^\s*$/],
    ["tag-id", /^\s*---\s?@[a-zA-Z]/],
    ["tag", /^\s*---\s?@(?<tag>name|param|return|returns|example)\b\s*(?<content>.*)$/],
    // LuaCATS: ---@param <name> <type> [description]
    ["param-content", /^(?<name>\S+)\s+(?<type>\S+)(?:\s+(?<content>.*))?$/],
    // LuaCATS: ---@returns <type> [description]
    ["return-content", /^(?<type>\S+)(?:\s+(?<rest>.*))?$/],
    ["function", /^\s*function\s+(?<name>(?<scope>[a-zA-Z_]\w*(?=[.:]))?(?<delimiter>[.:])?(?<method>[a-zA-Z_]\w*))\s*\((?<parms>.+)?\)\s*(?:end)?$/],
  ])
}
