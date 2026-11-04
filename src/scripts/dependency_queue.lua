local DependencyQueueClass = Glu.glass.register({
  class_name = "DependencyQueueClass",
  name = "dependency_queue",
  extends = "queue",
  call = "new_dependency_queue",
  dependencies = { "queue", "table", },
  setup = function(___, self)
    -- Every install with handlers registered, added and removed by the install
    -- itself. Each Glu instance has its own, so a package only reaches its own.
    self.installs = {}

    --- Ends every queue still running on this Glu instance without invoking
    --- their callbacks. Used when the package is uninstalled, as a callback may
    --- touch state that has already been wiped.
    function self.clean_up_all()
      for install in pairs(self.installs) do
        install.clean_up()
      end
    end

    --- Builds a queue that installs any of the given Mudlet packages that are not already installed.
    --- Filters out already-installed packages, downloads each remaining package into its own
    --- temporary directory, installs it from there, and invokes the callback with success and a
    --- message when finished. Each call returns its own object, so queues can run side by side.
    ---
    ---@param packages table List of package descriptors, each a {name, url} table.
    ---@param cb function Callback called with a success boolean and a message string when finished.
    ---@param timeout number? Seconds to wait for each package to download. Waits indefinitely if omitted.
    ---@return table|nil install The dependency install object, or nil when every package is already installed.
    function self.new_dependency_queue(packages, cb, timeout)
      ___.v.type(timeout, "number", 3, true)
      -- The range tempTimer accepts.
      ___.v.test(timeout == nil or (timeout > 0 and timeout < 86400), timeout, 3, true)

      local installed = getPackages()
      local not_installed = table.n_filter(packages, function(package)
        return table.index_of(installed, package.name) == nil
      end) or {}

      -- We have no packages not installed, so just return as if we're done.
      if #not_installed == 0 then
        cb(true, "All dependencies are already installed.")
        return
      end

      local gl = ___.get_glass("dependency_install")

      return gl({ packages = not_installed, cb = cb, timeout = timeout }, self).prepare()
    end
  end
})
