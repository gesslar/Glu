local HttpRequestClass = Glu.glass.register({
  name = "http_request",
  class_name = "HttpRequestClass",
  dependencies = { "table", },
  setup = function(___, self, options)
    self.options = options

    --- Performs the HTTP request described by `self.options`.
    --- Registers Mudlet named event handlers for the matching sysHttp
    --- Done/Error events, then invokes the appropriate global HTTP function
    --- (`getHTTP`, `postHTTP`, `customHTTP`, etc.). On completion it builds an
    --- `http_response`, writes the body to `saveTo` when requested, invokes the
    --- callback, and cleans up its event handlers.
    ---
    ---@return table request The request object.
    ---@example
    --- ```lua
    --- request.execute()
    --- ```
    function self.execute()
      local owner = self.container

      self.id = ___.id()

      -- Headers
      if not self.options.headers then self.options.headers = {} end
      if type(self.options.headers) ~= "table" then
        error("headers must be a table")
      end

      self.headers = self.options.headers

      local function done(response_data)
        local ob_id = response_data.id
        local ob = owner.find_request(ob_id)

        assert(ob, "HTTP request not found")

        if self.options.saveTo and not response_data.error then
          ___.fd.write_file(self.options.saveTo, response_data.data, true, true)
        end

        local cb = self.options.callback
        local gl = ___.get_glass("http_response")
        local response = gl(response_data, owner)

        cb(response)
        deleteAllNamedEventHandlers(ob_id)
        owner.delete_request(ob_id)
        ob = nil
        response_data = nil
      end

      -- Events to listen for
      local events = {}
      local lc = table.index_of(owner.http_types, self.options.method) and
          string.lower(self.options.method) or "custom"
      local uc = string.title(___.string.capitalize(lc))

      self.method_lc = lc
      self.method_uc = uc
      self.custom = lc == "custom"

      local func_name = string.format("%sHTTP", lc)
      local func = _G[func_name]

      assert(type(func) == "function", "HTTP method " .. func_name .. " not found")

      for _, event in ipairs({ "Done", "Error" }) do
        local event_mod = string.format("sys%sHttp%s", uc, event)
        table.insert(events, { event, event_mod })
      end

      local function only_indexed(t)
        local tmp = {}
        for i = 1, #t do
          tmp[i] = t[i]
        end
        return tmp
      end

      for _, event in ipairs(events) do
        local _, event_name = unpack(event)
        registerNamedEventHandler(
          self.id,
          event_name,
          event_name,
          function(e, ...)
            local response = {
              event = e,
              id = self.id,
            }

            local result
            local args = only_indexed({ ... })
            -- Custom events carry the method third; the rest then line up
            -- with every other event.
            local method = self.custom and table.remove(args, 3) or nil
            if rex.match(e, "sys(?:\\w+)HttpError$") then
              result = {
                error = args[1],
                url = args[2],
                server = args[3],
                body = args[4],
                request_id = args[5],
              }
            elseif rex.match(e, "sys(?:\\w+)HttpDone$") then
              result = {
                url = args[1],
                data = args[2],
                server = args[3],
                request_id = args[4],
              }
            else
              error("Unknown event: " .. e)
            end

            -- Mudlet versions without request ids leave both sides nil.
            if result.request_id ~= self.request_id then return end

            result.method = method

            ___.table.add(response, result)

            done(response)
          end
        )
      end

      local url, headers = self.options.url, self.options.headers
      local data = self.options.data or ""

      local ok, err, _, request_id = pcall(function()
        if self.custom then
          return func(self.options.method, data, url, headers)
        elseif lc == "post" or lc == "put" then
          return func(data, url, headers)
        end

        return func(url, headers)
      end)

      if not ok then
        deleteAllNamedEventHandlers(self.id)
        error("Error calling HTTP method " .. tostring(self.custom) .. " " .. tostring(func) .. ": " .. tostring(err))
      end

      self.request_id = request_id

      return self
    end
  end
})
