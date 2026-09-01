local DependencyQueueClass = Glu.glass.register({
  class_name = "DependencyQueueClass",
  name = "dependency_queue",
  extends = "queue",
  call = "new_dependency_queue",
  dependencies = { "queue", "table", "fd", "url", },
  setup = function(___, self)
    --- Builds a queue that installs any of the given Mudlet packages that are not already installed.
    --- Filters out already-installed packages, downloads each remaining package into its own
    --- temporary directory, installs it from there, and invokes the callback with success and a
    --- message when finished.
    ---
    ---@param packages table List of package descriptors, each a {name, url} table.
    ---@param cb function Callback called with a success boolean and a message string when finished.
    ---@return object self The dependency queue object.
    function self.new_dependency_queue(packages, cb)
      local installed = getPackages()
      local not_installed = table.n_filter(packages, function(package)
        return table.index_of(installed, package.name) == nil
      end) or {}

      -- We have no packages not installed, so just return as if we're done.
      if #not_installed == 0 then
        cb(true, "All dependencies are already installed.")
        return
      end

      local id = ___.id()
      local this = {
        id = id,
        cb = cb,
        queue = self.new_queue(),
        packages = not_installed,
        current = nil,
        handler_name = f "dependency_{id}_installed",
      }
      ___.table.add(self, this)

      for _, package in ipairs(not_installed) do
        local func = function()
          cecho("Installing dependency `<b>" .. package.name .. "</b>`...\n")

          -- Mudlet's download and install events are global, and the URL they
          -- carry may have been rewritten by redirection, so the URL cannot
          -- identify an event as ours. The local path can: we name the file
          -- for a fresh UUID that nothing else in the profile can collide
          -- with. The name is ours to choose because Mudlet takes the package
          -- name from the archive's config.lua manifest, not from the file --
          -- only the extension has to survive, since that selects the format.
          local dir = ___.fd.fix_path(getMudletHomeDir() .. "/tmp")
          local ok, err = ___.fd.assure_dir(dir)
          if not ok then
            local reason = err or "unknown error"
            self.cb(false, f "Could not create a temporary directory for `<b>{package.name}</b>`: {reason}\n")
            self.clean_up()
            return
          end

          local parsed = ___.url.parse(package.url)
          local ext = parsed and parsed.file and string.match(parsed.file, "%.(%w+)$") or "mpackage"

          self.current = {
            package = package,
            target = ___.fd.fix_path(dir .. "/" .. ___.id() .. "." .. ext),
          }

          downloadFile(self.current.target, package.url)
        end

        self.queue.push(func)
      end

      registerNamedEventHandler("glu", self.handler_name, "sysInstallPackage",
        function(event, package, file)
          -- sysInstallPackage reports the file Mudlet was asked to install, so
          -- the same UUID path that identifies our downloads identifies our
          -- installs. sysInstall carries only a package name, which any other
          -- component installing something of that name would also produce.
          if not self.is_ours(file) then return end

          self.discard_temp()
          ___.table.shift(self.packages)
          tempTimer(1, function()
            local q, count = self.queue.execute()
            if #self.packages == 0 then
              self.cb(true, nil)
              self.clean_up()
            end
          end)
        end
      )

      registerNamedEventHandler("glu", self.handler_name .. "_download_done", "sysDownloadDone",
        function(event, local_file)
          if not self.is_ours(local_file) then return end

          installPackage(self.current.target)
        end
      )

      registerNamedEventHandler("glu", self.handler_name .. "_download_error", "sysDownloadError",
        function(event, err, local_file, url)
          if not self.is_ours(local_file) then return end

          local name = self.current.package.name
          local reason = err or "unknown error"

          self.discard_temp()
          self.cb(false, f "Failed to download dependency `<b>{name}</b>`: {reason}\nCleaning up.\n")
          self.clean_up()
        end
      )

      --- Determines whether a download or install event refers to the file this
      --- queue is currently working on. The path was chosen by us and contains a UUID,
      --- so an exact match is unambiguous and no guessing is required.
      ---
      ---@param local_file string? The local path reported by the download event.
      ---@return boolean result Whether the event refers to our download.
      function self.is_ours(local_file)
        if not self.current or type(local_file) ~= "string" then return false end

        return ___.fd.fix_path(local_file) == self.current.target
      end

      --- Removes the temporary file holding the current download, if any.
      --- Safe to call more than once.
      function self.discard_temp()
        local current = self.current
        if not current then return end

        if ___.fd.file_exists(current.target) then ___.fd.rmfile(current.target) end

        self.current = nil
      end

      --- Removes the registered event handlers and tears down the queue.
      --- Deletes the named sysInstallPackage, sysDownloadDone and sysDownloadError
      --- handlers, discards any temporary download, and clears the handler name
      --- and queue.
      function self.clean_up()
        self.discard_temp()

        deleteNamedEventHandler("glu", self.handler_name)
        deleteNamedEventHandler("glu", self.handler_name .. "_download_done")
        deleteNamedEventHandler("glu", self.handler_name .. "_download_error")
        self.handler_name = nil
        self.queue = nil
      end

      --- Begins executing the queue.
      --- Executes the queue if it exists, otherwise returns a not-found error.
      ---
      ---@return any|nil result The result of the queue execution, or nil when the queue is not found.
      ---@return string? err The error message "Queue not found" when the queue is missing.
      function self.start()
        if not self.queue then
          return nil, "Queue not found"
        end
        return self.queue.execute()
      end

      return self
    end
  end
})
