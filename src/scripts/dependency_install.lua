local DependencyInstallClass = Glu.glass.register({
  name = "dependency_install",
  class_name = "DependencyInstallClass",
  dependencies = { "table", "fd", "url", },
  setup = function(___, self, options)
    self.options = options

    --- Sets up one run of the dependency queue: queues a download and install
    --- for each package and registers the event handlers that drive them.
    ---
    ---@return table self The install object.
    function self.prepare()
      local id = ___.id()

      self.id = id
      self.cb = self.options.cb
      self.timeout = self.options.timeout
      self.queue = self.container.new_queue()
      self.packages = self.options.packages
      self.current = nil
      self.handler_name = f "dependency_{id}_installed"

      for _, package in ipairs(self.packages) do
        local func = function()
          local name = package.name

          cecho("Installing dependency `<b>" .. name .. "</b>`...\n")

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
            self.fail("Could not create a temporary directory for `<b>" .. name .. "</b>`: " .. reason .. "\n")
            return
          end

          local parsed = ___.url.parse(package.url)
          local ext = parsed and parsed.file and string.match(parsed.file, "%.(%w+)$") or "mpackage"
          local target = ___.fd.fix_path(dir .. "/" .. ___.id() .. "." .. ext)

          self.current = {
            package = package,
            target = target,
          }

          -- A refused download raises no event, so nothing else would end the queue.
          local started, refusal = downloadFile(target, package.url)
          if not started then
            local reason = refusal or "unknown error"
            self.fail("Failed to download dependency `<b>" .. name .. "</b>`: " .. reason .. "\nCleaning up.\n")
            return
          end

          -- Mudlet can't cancel a download, so this only stops the waiting. If the
          -- transfer does finish later, its file stays behind in the temp directory.
          local timeout = self.timeout
          if timeout then
            self.current.timer = tempTimer(timeout, function()
              if not self.is_ours(target) then return end

              self.current.timer = nil
              self.fail("Timed out downloading dependency `<b>" .. name .. "</b>` after " ..
                timeout .. " seconds.\nCleaning up.\n")
            end)
          end
        end

        self.queue.push(func)
      end

      registerNamedEventHandler("glu", self.handler_name, "sysInstallPackage",
        function(_, installed_name, file, errors)
          -- sysInstallPackage reports the file Mudlet was asked to install, so
          -- the same UUID path that identifies our downloads identifies our
          -- installs. sysInstall carries only a package name, which any other
          -- component installing something of that name would also produce.
          if not self.is_ours(file) then return end

          -- Mudlet adds the errors only when part of the package failed to load.
          -- Left installed, a later run would find the package and report the
          -- dependency as met. The name comes from the event because it is the
          -- archive's own, which need not match the name we were given.
          if errors then
            local name = self.current.package.name
            local removed, refusal = uninstallPackage(installed_name)
            local outcome = removed and "It has been uninstalled." or
                "It could not be uninstalled: " .. tostring(refusal)
            self.fail("Dependency `<b>" .. name .. "</b>` installed with errors: " .. errors ..
              "\n" .. outcome .. "\nCleaning up.\n")
            return
          end

          self.discard_temp()
          ___.table.shift(self.packages)
          tempTimer(1, function()
            -- Ended while this was waiting, such as by the package being uninstalled.
            if not self.queue then return end

            self.queue.execute()
            if #self.packages == 0 then
              -- Cleaned up first, so a callback that throws can't leave handlers behind.
              self.clean_up()
              self.cb(true, nil)
            end
          end)
        end
      )

      registerNamedEventHandler("glu", self.handler_name .. "_download_done", "sysDownloadDone",
        function(_, local_file)
          if not self.is_ours(local_file) then return end

          self.stop_timeout()

          -- A refused install raises no event, so nothing else would end the queue.
          local started, refusal = installPackage(self.current.target)
          if not started then
            local name = self.current.package.name
            local reason = refusal or "unknown error"
            self.fail("Failed to install dependency `<b>" .. name .. "</b>`: " .. reason .. "\nCleaning up.\n")
            return
          end

          -- The install has finished by now and Mudlet raises sysInstallPackage
          -- from a zero timer it has already set, so that fires before this one.
          -- If the file is still current here, the event isn't coming: the package
          -- was removed before it went out.
          local target = self.current.target
          tempTimer(0, function()
            if self.current and self.current.target == target then
              local name = self.current.package.name
              self.fail("Dependency `<b>" .. name .. "</b>` was removed as soon as it was installed.\nCleaning up.\n")
            end
          end)
        end
      )

      registerNamedEventHandler("glu", self.handler_name .. "_download_error", "sysDownloadError",
        function(_, err, local_file)
          if not self.is_ours(local_file) then return end

          local name = self.current.package.name
          local reason = err or "unknown error"

          self.fail("Failed to download dependency `<b>" .. name .. "</b>`: " .. reason .. "\nCleaning up.\n")
        end
      )

      self.container.installs[self] = true

      return self
    end

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

    --- Cancels the current download's timeout, if it has one.
    --- Safe to call more than once.
    function self.stop_timeout()
      local current = self.current
      if not current or not current.timer then return end

      killTimer(current.timer)
      current.timer = nil
    end

    --- Removes the temporary file holding the current download, if any, and
    --- cancels its timeout. Safe to call more than once.
    function self.discard_temp()
      local current = self.current
      if not current then return end

      self.stop_timeout()

      if ___.fd.file_exists(current.target) then ___.fd.rmfile(current.target) end

      self.current = nil
    end

    --- Ends the queue: tears it down, including any temporary download, then
    --- reports the failure through the callback. Cleaned up first, so a callback
    --- that throws can't leave handlers behind.
    ---
    ---@param message string The failure message passed to the callback.
    function self.fail(message)
      self.clean_up()
      self.cb(false, message)
    end

    --- Removes the registered event handlers and tears down the queue.
    --- Deletes the named sysInstallPackage, sysDownloadDone and sysDownloadError
    --- handlers, discards any temporary download, and clears the handler name
    --- and queue. Safe to call more than once, so a package's own uninstall
    --- handler can call it after Glu has already ended the queue.
    function self.clean_up()
      if not self.queue then return end

      self.discard_temp()

      deleteNamedEventHandler("glu", self.handler_name)
      deleteNamedEventHandler("glu", self.handler_name .. "_download_done")
      deleteNamedEventHandler("glu", self.handler_name .. "_download_error")
      self.handler_name = nil
      self.container.delete(self.queue.id)
      self.queue = nil
      self.container.installs[self] = nil
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
  end
})
