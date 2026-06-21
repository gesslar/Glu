local GlassLoaderClass = Glu.glass.register({
  class_name = "GlassLoaderClass",
  name = "glass_loader",
  call = "load_glass",
  dependencies = { "try", "http", "fd", "string" },
  setup = function(___, self, instance_opts, container)

    --- Loads a "glass" (a Lua module/chunk) from a local file path or an
    --- http(s) URL. URL loads are asynchronous and the result is delivered
    --- through the callback. The loaded chunk can optionally be executed.
    ---
    ---@param opts table The options table. Fields: `path` (string) a local file path or http(s) URL, `cb`/`callback` (function, required) invoked with the loaded chunk on success or with (nil, errorMessage) on failure, and `execute` (boolean) whether to immediately execute the loaded chunk.
    ---@returns boolean|nil Returns `false` and an error message when no callback is provided; otherwise returns nothing, as results are delivered through the callback.
    ---@example
    --- ```lua
    --- glass_loader.load_glass({path = "https://example.com/thing.lua", cb = function(g, err) end})
    --- ```
    function self.load_glass(opts)
      opts = opts or {}
      local path = opts.path
      local cb = opts.cb or opts.callback
      local execute = opts.execute

      if type(cb) ~= "function" then
        return false, "callback is required"
      end

      if not path then
        cb(nil, "No file or url provided")
        return
      end

      local function load_glass_from_data(data)
        local f, err = loadstring(data)
        if not f then
          return nil, "Failed to load glass from data: " .. tostring(err)
        end

        return f
      end

      local function finalize(result)
        if not result then
          return nil, "Failed to load glass from path"
        end

        if execute then
          local ok, err = pcall(result)
          if not ok then
            return nil, "Failed to execute glass: " .. tostring(err)
          end
        end

        return result
      end

      if ___.string.starts_with(path, "https?://") then
        ___.http.get({ url = path }, function(response)
          if response.result.error then
            cb(nil, "Failed to load glass from url: " .. response.result.error)
            return
          end

          local result, err = load_glass_from_data(response.result.data)
          if not result then
            cb(nil, err)
            return
          end

          local final, exec_err = finalize(result)
          if not final then
            cb(nil, exec_err)
            return
          end

          cb(final)
        end)
        return
      end

      local data, err = ___.fd.read_file(path)
      if not data then
        cb(nil, err)
        return
      end

      local result, load_err = load_glass_from_data(data)
      if not result then
        cb(nil, load_err)
        return
      end

      local final, exec_err = finalize(result)
      if not final then
        cb(nil, exec_err)
        return
      end

      cb(final)
    end
  end
})
