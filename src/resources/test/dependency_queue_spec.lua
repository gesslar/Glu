describe("dependency_queue module", function()
  local g
  local installed

  setup(function()
    g = Glu("Glu")
    installed = getPackages()
  end)

  describe("new_dependency_queue", function()
    describe("when all packages are already installed", function()
      it("should call callback with true", function()
        if #installed == 0 then
          pending("no packages installed to test with")
          return
        end

        local cb_success = nil
        local packages = {}
        for i = 1, math.min(#installed, 2) do
          table.insert(packages, {name = installed[i], url = "https://example.com/" .. installed[i]})
        end

        g.dependency_queue.new_dependency_queue(
          packages,
          function(success, message)
            cb_success = success
          end
        )

        assert.is_true(cb_success)
      end)

      it("should pass the correct message to callback", function()
        if #installed == 0 then
          pending("no packages installed to test with")
          return
        end

        local cb_message = nil

        g.dependency_queue.new_dependency_queue(
          {{name = installed[1], url = "https://example.com/" .. installed[1]}},
          function(success, message)
            cb_message = message
          end
        )

        assert.are.equal("All dependencies are already installed.", cb_message)
      end)

      it("should not return self", function()
        if #installed == 0 then
          pending("no packages installed to test with")
          return
        end

        local result = g.dependency_queue.new_dependency_queue(
          {{name = installed[1], url = "https://example.com/" .. installed[1]}},
          function() end
        )

        assert.is_nil(result)
      end)
    end)

    describe("when packages need installing", function()
      local result

      before_each(function()
        result = g.dependency_queue.new_dependency_queue(
          {{name = "__glu_test_fake_pkg__", url = "https://example.com/fake"}},
          function() end
        )
      end)

      after_each(function()
        if result and result.clean_up then
          result.clean_up()
        end
      end)

      it("should return self", function()
        assert.is_truthy(result)
      end)

      it("should have a start method", function()
        assert.are.equal("function", type(result.start))
      end)

      it("should have a clean_up method", function()
        assert.are.equal("function", type(result.clean_up))
      end)

      it("should have a queue", function()
        assert.is_truthy(result.queue)
      end)

      it("should have a handler_name", function()
        assert.is_truthy(result.handler_name)
      end)

      it("should have the filtered packages list", function()
        assert.are.equal(1, #result.packages)
        assert.are.equal("__glu_test_fake_pkg__", result.packages[1].name)
      end)
    end)

    describe("with multiple uninstalled packages", function()
      it("should include all uninstalled packages", function()
        local result = g.dependency_queue.new_dependency_queue(
          {
            {name = "__glu_test_multi_a__", url = "https://example.com/a"},
            {name = "__glu_test_multi_b__", url = "https://example.com/b"},
            {name = "__glu_test_multi_c__", url = "https://example.com/c"},
          },
          function() end
        )

        assert.are.equal(3, #result.packages)
        result.clean_up()
      end)

      it("should filter out already-installed packages", function()
        if #installed == 0 then
          pending("no packages installed to test with")
          return
        end

        local result = g.dependency_queue.new_dependency_queue(
          {
            {name = installed[1], url = "https://example.com/" .. installed[1]},
            {name = "__glu_test_mixed__", url = "https://example.com/fake"},
          },
          function() end
        )

        assert.are.equal(1, #result.packages)
        assert.are.equal("__glu_test_mixed__", result.packages[1].name)
        result.clean_up()
      end)
    end)
  end)

  describe("clean_up", function()
    it("should nil out the queue", function()
      local result = g.dependency_queue.new_dependency_queue(
        {{name = "__glu_test_fake_cleanup_q__", url = "https://example.com/fake"}},
        function() end
      )

      result.clean_up()

      assert.is_nil(result.queue)
    end)

    it("should remove the queue from the queue list", function()
      local result = g.dependency_queue.new_dependency_queue(
        {{name = "__glu_test_fake_cleanup_l__", url = "https://example.com/fake"}},
        function() end
      )
      local id = result.queue.id

      assert.is_truthy(g.dependency_queue.get(id))

      result.clean_up()

      assert.is_nil(g.dependency_queue.get(id))
    end)

    it("should nil out the handler_name", function()
      local result = g.dependency_queue.new_dependency_queue(
        {{name = "__glu_test_fake_cleanup_h__", url = "https://example.com/fake"}},
        function() end
      )

      result.clean_up()

      assert.is_nil(result.handler_name)
    end)
  end)

  describe("install flow", function()
    local real_installPackage
    local real_tempTimer
    local real_downloadFile

    before_each(function()
      real_installPackage = _G.installPackage
      real_tempTimer = _G.tempTimer
      real_downloadFile = _G.downloadFile

      -- Mock tempTimer to execute callback immediately
      _G.tempTimer = function(time, code)
        -- Zero delay is the guard for a missing install event, which would otherwise
        -- fire before these specs raise that event by hand.
        if time == 0 then return 1 end

        if type(code) == "function" then
          code()
        elseif type(code) == "string" then
          loadstring(code)()
        end
        return 1
      end

      -- Mock installPackage to do nothing — we fire sysInstallPackage manually
      _G.installPackage = function() return true end

      -- Mock downloadFile to do nothing — we fire sysDownloadDone/Error manually
      _G.downloadFile = function(_, url) return true, url end
    end)

    after_each(function()
      _G.installPackage = real_installPackage
      _G.tempTimer = real_tempTimer
      _G.downloadFile = real_downloadFile

      -- Clean up the test package if it somehow got installed
      if table.index_of(getPackages(), "ThreshCopy") then
        uninstallPackage("ThreshCopy")
      end
    end)

    it("should complete when sysInstallPackage fires for the package", function()
      local cb_success = nil
      local cb_message = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "ThreshCopy", url = "https://example.com/fake"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()

      -- The download lands, then Mudlet fires sysInstallPackage once installed
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "ThreshCopy", dq.current.target)

      assert.is_true(cb_success)
      assert.is_nil(cb_message)
    end)

    it("should call callback with false on download error", function()
      local cb_success = nil
      local cb_message = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "ThreshCopy", url = "https://example.com/fake.mpackage"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()

      -- Mudlet fires sysDownloadError(error, local_file, url, response, body) for the file we chose
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/fake.mpackage", {}, "")

      assert.is_false(cb_success)
      assert.is_truthy(cb_message)
    end)

    it("should install from the downloaded file when sysDownloadDone fires", function()
      local installed_from = nil
      _G.installPackage = function(path) installed_from = path; return true end

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgDone", url = "https://example.com/FakePkgDone.mpackage"}},
        function() end
      )

      dq.start()

      local target = dq.current.target
      raiseEvent("sysDownloadDone", target, 1024, {})

      assert.are.equal(target, installed_from)
      dq.clean_up()
    end)

    it("should download to a uuid file name keeping the url extension", function()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgPath", url = "https://example.com/pkg/FakePkgPath.mpackage"}},
        function() end
      )

      dq.start()

      -- The name is a uuid; only the extension is carried over from the url
      assert.is_truthy(string.find(dq.current.target, "%.mpackage$"))
      assert.is_falsy(string.find(dq.current.target, "FakePkgPath"))
      assert.is_truthy(string.find(dq.current.target,
        "/%x+%-%x+%-%x+%-%x+%-%x+%.mpackage$"))
      dq.clean_up()
    end)

    it("should keep a non-mpackage extension from the url", function()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgZip", url = "https://example.com/pkg/FakePkgZip.zip"}},
        function() end
      )

      dq.start()

      assert.is_truthy(string.find(dq.current.target, "%.zip$"))
      dq.clean_up()
    end)

    it("should install multiple packages in sequence", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {
          {name = "FakePkgA", url = "https://example.com/a"},
          {name = "FakePkgB", url = "https://example.com/b"},
        },
        function(success, message)
          cb_success = success
        end
      )

      dq.start()

      -- First package downloads, then installs
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgA", dq.current.target)
      -- Second package downloads, then installs
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgB", dq.current.target)

      assert.is_true(cb_success)
    end)
  end)

  describe("empty package list", function()
    it("should call callback with true immediately", function()
      local cb_success = nil
      local cb_message = nil

      g.dependency_queue.new_dependency_queue(
        {},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      assert.is_true(cb_success)
      assert.are.equal("All dependencies are already installed.", cb_message)
    end)

    it("should not return self", function()
      local result = g.dependency_queue.new_dependency_queue(
        {},
        function() end
      )

      assert.is_nil(result)
    end)
  end)

  describe("install flow edge cases", function()
    local real_installPackage
    local real_tempTimer
    local real_downloadFile

    -- Uses the real install, timers and uninstall. Only the download is stood in
    -- for, by writing a package holding this script to the path the queue chose.
    local function use_real_install(script)
      _G.tempTimer = real_tempTimer
      _G.installPackage = real_installPackage
      _G.downloadFile = function(path, url)
        local file = assert(io.open(path, "w"))
        file:write(string.format([[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE MudletPackage>
<MudletPackage version="1.001">
  <ScriptPackage>
    <Script isActive="yes" isFolder="no">
      <name>probe</name>
      <packageName></packageName>
      <script>%s</script>
      <eventHandlerList />
    </Script>
  </ScriptPackage>
</MudletPackage>
]], script))
        file:close()
        real_tempTimer(0, function() raiseEvent("sysDownloadDone", path, 1024, {}) end)
        return true, url
      end
    end

    local function pump_until(condition)
      for _ = 1, 60 do
        if condition() then return end
        pumpEvents(50)
      end
    end

    before_each(function()
      real_installPackage = _G.installPackage
      real_tempTimer = _G.tempTimer
      real_downloadFile = _G.downloadFile

      _G.tempTimer = function(time, code)
        -- Zero delay is the guard for a missing install event, which would otherwise
        -- fire before these specs raise that event by hand.
        if time == 0 then return 1 end

        if type(code) == "function" then
          code()
        elseif type(code) == "string" then
          loadstring(code)()
        end
        return 1
      end

      _G.installPackage = function() return true end
      _G.downloadFile = function(_, url) return true, url end
    end)

    after_each(function()
      _G.installPackage = real_installPackage
      _G.tempTimer = real_tempTimer
      _G.downloadFile = real_downloadFile
    end)

    it("should ignore sysInstallPackage for a file that is not ours", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgX", url = "https://example.com/x"}},
        function(success, message)
          cb_success = success
        end
      )

      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})

      -- Fire an install for a different package's file — should be ignored
      raiseEvent("sysInstallPackage", "SomeOtherPackage", "/tmp/elsewhere/SomeOtherPackage.mpackage")

      assert.is_nil(cb_success)
      dq.clean_up()
    end)

    it("should handle download error on first of multiple packages", function()
      local cb_success = nil
      local cb_message = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {
          {name = "FakePkgFirst", url = "https://example.com/first"},
          {name = "FakePkgSecond", url = "https://example.com/second"},
        },
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()

      -- First package fails to download
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/first", {}, "")

      assert.is_false(cb_success)
      assert.is_truthy(cb_message)
    end)

    it("should handle download error on second of multiple packages", function()
      local cb_success = nil
      local cb_message = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {
          {name = "FakePkgAlpha", url = "https://example.com/alpha"},
          {name = "FakePkgBeta", url = "https://example.com/beta"},
        },
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()

      -- First package succeeds
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgAlpha", dq.current.target)

      -- Reset to check second callback
      cb_success = nil
      cb_message = nil

      -- Second package fails; current now points at the second download
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/beta", {}, "")

      assert.is_false(cb_success)
      assert.is_truthy(cb_message)
    end)

    it("should clean up event handlers after successful install", function()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgCleanup", url = "https://example.com/cleanup"}},
        function() end
      )

      local handler_name = dq.handler_name
      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgCleanup", dq.current.target)

      -- After completion, handler_name should be nil (cleaned up)
      assert.is_nil(dq.handler_name)
      assert.is_nil(dq.queue)
    end)

    it("should ignore a download error for an unrelated download", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgMine", url = "https://example.com/mine.mpackage"}},
        function(success, message)
          cb_success = success
        end
      )

      dq.start()

      -- Something else in the profile fails to download — a path we did not choose
      raiseEvent("sysDownloadError", "404 not found", "/tmp/theirs.mpackage",
        "https://elsewhere.example.com/theirs.mpackage", {}, "")

      assert.is_nil(cb_success)
      assert.is_not_nil(dq.handler_name)
      assert.is_not_nil(dq.queue)

      -- Our own download and install still complete normally afterwards
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgMine", dq.current.target)

      assert.is_true(cb_success)
    end)

    it("should ignore an unrelated download sharing our file name", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgSame", url = "https://example.com/same.mpackage"}},
        function(success, message)
          cb_success = success
        end
      )

      dq.start()

      -- Same final file name, different directory: the uuid keeps it distinct
      local collision = string.gsub(dq.current.target, "same%.mpackage$", "") ..
        "../other/same.mpackage"

      raiseEvent("sysDownloadError", "404 not found", collision,
        "https://elsewhere.example.com/same.mpackage", {}, "")

      assert.is_nil(cb_success)
      assert.is_not_nil(dq.queue)
      dq.clean_up()
    end)

    it("should match a download error however the url was redirected", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgRedir", url = "https://example.com/pkg/redir.mpackage"}},
        function(success, message)
          cb_success = success
        end
      )

      dq.start()

      -- Redirection rewrote the url to a signed path with no recognisable file
      -- name; identity comes from the local path, so this is still ours
      raiseEvent("sysDownloadError", "connection reset", dq.current.target,
        "https://cdn.example.net/asset/5dd0c819-e4ee-447e-b18f-24a7b5ed17fe?sig=abc", {}, "")

      assert.is_false(cb_success)
    end)

    it("should ignore an install of the same name from elsewhere", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {
          {name = "FakePkgRace", url = "https://example.com/race.mpackage"},
          {name = "FakePkgAfter", url = "https://example.com/after.mpackage"},
        },
        function(success, message)
          cb_success = success
        end
      )

      dq.start()

      local target = dq.current.target

      -- Another component installs a package of the same name from its own
      -- file — same name, different path, so it is not ours
      raiseEvent("sysInstallPackage", "FakePkgRace", "/tmp/elsewhere/FakePkgRace.mpackage")

      assert.is_nil(cb_success)
      assert.are.equal(2, #dq.packages)
      assert.is_not_nil(dq.current)
      assert.are.equal(target, dq.current.target)

      -- Our own download and install still proceed normally
      raiseEvent("sysDownloadDone", target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgRace", target)

      assert.are.equal(1, #dq.packages)
      dq.clean_up()
    end)

    it("should not discard the active download on an install from elsewhere", function()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgKeep", url = "https://example.com/keep.mpackage"}},
        function() end
      )

      dq.start()

      local target = dq.current.target
      raiseEvent("sysInstallPackage", "FakePkgKeep", "/tmp/elsewhere/FakePkgKeep.mpackage")

      -- Our in-flight download must not be discarded
      assert.is_not_nil(dq.current)
      assert.are.equal(target, dq.current.target)
      dq.clean_up()
    end)

    it("should ignore sysDownloadDone for an unrelated download", function()
      local installed = false
      _G.installPackage = function() installed = true; return true end

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgOther", url = "https://example.com/other.mpackage"}},
        function() end
      )

      dq.start()

      raiseEvent("sysDownloadDone", "/tmp/not-ours.mpackage", 1024, {})

      assert.is_false(installed)
      dq.clean_up()
    end)

    it("should fail the queue when downloadFile refuses", function()
      local cb_success, cb_message

      -- Mudlet's real downloadFile, which refuses this scheme without touching the network
      _G.downloadFile = real_downloadFile

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgRefusedDl", url = "ftp://example.com/refused.mpackage"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()

      assert.is_false(cb_success)
      assert.is_truthy(cb_message:find("FakePkgRefusedDl", 1, true))
      assert.is_truthy(cb_message:find("unsupported scheme", 1, true))
      assert.is_nil(dq.queue)
      assert.is_nil(dq.handler_name)
    end)

    it("should fail the queue when installPackage refuses", function()
      local cb_success, cb_message

      -- Mudlet's real installPackage, which refuses a file that doesn't exist
      _G.installPackage = real_installPackage

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgRefusedIn", url = "https://example.com/refused.mpackage"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})

      assert.is_false(cb_success)
      assert.is_truthy(cb_message:find("FakePkgRefusedIn", 1, true))
      assert.is_nil(dq.queue)
      assert.is_nil(dq.handler_name)
    end)

    it("should fail the queue when a package installs with errors", function()
      local cb_success, cb_message
      local downloads = 0
      local uninstalled

      local real_uninstallPackage = _G.uninstallPackage
      finally(function() _G.uninstallPackage = real_uninstallPackage end)
      _G.uninstallPackage = function(name)
        uninstalled = name
        return true
      end

      _G.downloadFile = function(_, url)
        downloads = downloads + 1
        return true, url
      end

      local dq = g.dependency_queue.new_dependency_queue(
        {
          {name = "FakePkgBroken", url = "https://example.com/broken.mpackage"},
          {name = "FakePkgNever", url = "https://example.com/never.mpackage"},
        },
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "NameFromArchive", dq.current.target, "bad trigger; bad script")

      assert.is_false(cb_success)
      assert.is_truthy(cb_message:find("FakePkgBroken", 1, true))
      assert.is_truthy(cb_message:find("bad trigger; bad script", 1, true))
      assert.are.equal("NameFromArchive", uninstalled)
      assert.are.equal(1, downloads)
      assert.is_nil(dq.queue)
      assert.is_nil(dq.handler_name)
    end)

    it("should report it when a package with errors can't be uninstalled", function()
      local cb_message

      local real_uninstallPackage = _G.uninstallPackage
      finally(function() _G.uninstallPackage = real_uninstallPackage end)
      _G.uninstallPackage = function() return nil, "a profile save is in progress" end

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgStuck", url = "https://example.com/stuck.mpackage"}},
        function(_, message) cb_message = message end
      )

      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgStuck", dq.current.target, "bad script")

      assert.is_truthy(cb_message:find("a profile save is in progress", 1, true))
    end)

    it("should remove a package that really installs with errors", function()
      local cb_success, cb_message

      use_real_install("this is not ( lua")

      local before = #getPackages()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgReallyBroken", url = "https://example.com/broken.xml"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()
      pump_until(function() return cb_success ~= nil end)

      assert.is_false(cb_success)
      assert.is_truthy(cb_message:find("It has been uninstalled.", 1, true))
      assert.are.equal(before, #getPackages())
    end)

    it("should fail the queue when a package is removed before its install event", function()
      local cb_success, cb_message

      use_real_install("local fine = true")

      -- sysInstall goes out first, and Mudlet then drops sysInstallPackage
      -- because the package is gone
      finally(function() deleteAllNamedEventHandlers("glu_test_guard") end)
      registerNamedEventHandler("glu_test_guard", "remove", "sysInstall", function(_, name)
        uninstallPackage(name)
      end)

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgRemoved", url = "https://example.com/removed.xml"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()
      pump_until(function() return cb_success ~= nil end)

      assert.is_false(cb_success)
      assert.is_truthy(cb_message:find("FakePkgRemoved", 1, true))
      assert.is_nil(dq.queue)
    end)

    it("should not trip the install guard on a normal install", function()
      local cb_success, cb_message
      local installed_name

      use_real_install("local fine = true")

      finally(function()
        deleteAllNamedEventHandlers("glu_test_guard")
        if installed_name then uninstallPackage(installed_name) end
      end)
      registerNamedEventHandler("glu_test_guard", "note", "sysInstall", function(_, name)
        installed_name = name
      end)

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgFine", url = "https://example.com/fine.xml"}},
        function(success, message)
          cb_success = success
          cb_message = message
        end
      )

      dq.start()
      pump_until(function() return cb_success ~= nil end)

      assert.is_true(cb_success)
      assert.is_nil(cb_message)
      assert.is_truthy(installed_name)
    end)

    describe("when the callback throws", function()
      it("should still clean up on failure", function()
        local dq = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgThrowFail", url = "https://example.com/fail.mpackage"}},
          function() error("callback failed") end
        )

        dq.start()

        assert.is_false(pcall(dq.fail, "failed"))
        assert.is_nil(dq.handler_name)
        assert.is_nil(dq.queue)
      end)

      it("should still clean up on success", function()
        local pending_timer

        local dq = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgThrowOk", url = "https://example.com/ok.mpackage"}},
          function() error("callback failed") end
        )

        dq.start()

        -- Holds the step that finishes the queue, so its error stays out of the event handler
        _G.tempTimer = function(_, code)
          pending_timer = code
          return 1
        end

        local target = dq.current.target
        raiseEvent("sysDownloadDone", target, 1024, {})
        raiseEvent("sysInstallPackage", "FakePkgThrowOk", target)

        assert.is_false(pcall(pending_timer))
        assert.is_nil(dq.handler_name)
        assert.is_nil(dq.queue)
      end)
    end)

    describe("timeout", function()
      it("should fail the queue when a download stalls", function()
        local cb_success, cb_message
        local installed_pkg = false

        _G.tempTimer = real_tempTimer
        _G.installPackage = function() installed_pkg = true; return true end

        local dq = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgStalled", url = "https://example.com/stalled.mpackage"}},
          function(success, message)
            cb_success = success
            cb_message = message
          end,
          0.05
        )

        dq.start()
        local target = dq.current.target

        pump_until(function() return cb_success ~= nil end)

        assert.is_false(cb_success)
        assert.is_truthy(cb_message:find("FakePkgStalled", 1, true))
        assert.is_truthy(cb_message:find("0.05 seconds", 1, true))
        assert.is_nil(dq.queue)

        -- The transfer can't be cancelled, so a late finish must be ignored
        raiseEvent("sysDownloadDone", target, 1024, {})
        assert.is_false(installed_pkg)
      end)

      it("should time each download separately", function()
        local cb_success
        local installed_names = {}

        use_real_install("local fine = true")

        finally(function()
          deleteAllNamedEventHandlers("glu_test_timeout")
          for _, name in ipairs(installed_names) do uninstallPackage(name) end
        end)
        registerNamedEventHandler("glu_test_timeout", "note", "sysInstall", function(_, name)
          table.insert(installed_names, name)
        end)

        -- The queue waits a second between packages, so a timeout shared
        -- across the whole queue would run out before the second one
        local dq = g.dependency_queue.new_dependency_queue(
          {
            {name = "FakePkgTimedA", url = "https://example.com/a.xml"},
            {name = "FakePkgTimedB", url = "https://example.com/b.xml"},
          },
          function(success) cb_success = success end,
          0.5
        )

        dq.start()
        pump_until(function() return cb_success ~= nil end)

        assert.is_true(cb_success)
        assert.are.equal(2, #installed_names)
      end)

      it("should name the package that stalled when it isn't the first", function()
        local cb_success, cb_message
        local installed_name

        use_real_install("local fine = true")

        finally(function()
          deleteAllNamedEventHandlers("glu_test_timeout")
          if installed_name then uninstallPackage(installed_name) end
        end)
        registerNamedEventHandler("glu_test_timeout", "note", "sysInstall", function(_, name)
          installed_name = name
        end)

        local real_install_download = _G.downloadFile
        local downloads = 0
        _G.downloadFile = function(path, url)
          downloads = downloads + 1
          if downloads == 1 then return real_install_download(path, url) end
          return true, url
        end

        local dq = g.dependency_queue.new_dependency_queue(
          {
            {name = "FakePkgFirstOk", url = "https://example.com/first.xml"},
            {name = "FakePkgSecondStalls", url = "https://example.com/second.xml"},
          },
          function(success, message)
            cb_success = success
            cb_message = message
          end,
          0.2
        )

        dq.start()
        pump_until(function() return cb_success ~= nil end)

        assert.is_false(cb_success)
        assert.is_truthy(cb_message:find("FakePkgSecondStalls", 1, true))
      end)

      it("should not set a timer when no timeout is given", function()
        local dq = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgNoTimeout", url = "https://example.com/none.mpackage"}},
          function() end
        )

        dq.start()

        assert.is_nil(dq.current.timer)
        dq.clean_up()
      end)

      it("should reject a timeout tempTimer wouldn't accept", function()
        for _, bad in ipairs({ 0, -1, 86400, "soon" }) do
          assert.has_error(function()
            g.dependency_queue.new_dependency_queue(
              {{name = "FakePkgBadTimeout", url = "https://example.com/bad.mpackage"}},
              function() end,
              bad
            )
          end)
        end
      end)
    end)

    describe("queues running side by side", function()
      it("should give each call its own object and packages", function()
        local a = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgSideA", url = "https://example.com/a.mpackage"}},
          function() end
        )
        local b = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgSideB", url = "https://example.com/b.mpackage"}},
          function() end
        )

        assert.is_false(rawequal(a, b))
        assert.are.equal("FakePkgSideA", a.packages[1].name)
        assert.are.equal("FakePkgSideB", b.packages[1].name)

        a.clean_up()
        assert.is_not_nil(b.queue)
        b.clean_up()
      end)

      it("should finish each queue through its own callback", function()
        local a_success, b_success
        local installs = 0
        _G.installPackage = function() installs = installs + 1; return true end

        local a = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgRunA", url = "https://example.com/a.mpackage"}},
          function(success) a_success = success end
        )
        local b = g.dependency_queue.new_dependency_queue(
          {{name = "FakePkgRunB", url = "https://example.com/b.mpackage"}},
          function(success) b_success = success end
        )

        a.start()
        b.start()

        raiseEvent("sysDownloadDone", a.current.target, 1024, {})
        assert.are.equal(1, installs)

        raiseEvent("sysInstallPackage", "FakePkgRunA", a.current.target)
        assert.is_true(a_success)
        assert.is_nil(b_success)
        assert.is_not_nil(b.queue)

        raiseEvent("sysDownloadDone", b.current.target, 1024, {})
        raiseEvent("sysInstallPackage", "FakePkgRunB", b.current.target)
        assert.is_true(b_success)
      end)
    end)

    it("should clean up event handlers after download error", function()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgErrClean", url = "https://example.com/errclean"}},
        function() end
      )

      dq.start()
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/errclean", {}, "")

      assert.is_nil(dq.handler_name)
      assert.is_nil(dq.queue)
    end)
  end)

  describe("when the package is uninstalled", function()
    -- sysUninstall kills the instance it names, so nothing here can use the shared one.
    local package_name = "__glu_test_dq_uninstall__"
    local other_package_name = "__glu_test_dq_uninstall_other__"
    local instance
    local cb_calls
    local real_tempTimer
    local real_downloadFile
    local real_installPackage

    local function count_handlers(handler_name)
      local count = 0
      local registered = getNamedEventHandlers("glu")
      for _, name in ipairs({ handler_name, handler_name .. "_download_done", handler_name .. "_download_error" }) do
        if table.index_of(registered, name) then count = count + 1 end
      end
      return count
    end

    local function new_queue(glu, timeout, packages)
      return glu.dependency_queue.new_dependency_queue(
        packages or {{name = "FakePkgUninstall", url = "https://example.com/uninstall.mpackage"}},
        function() cb_calls = cb_calls + 1 end,
        timeout
      )
    end

    before_each(function()
      real_tempTimer = _G.tempTimer
      real_downloadFile = _G.downloadFile
      real_installPackage = _G.installPackage

      _G.installPackage = function() return true end
      _G.downloadFile = function(path, url)
        local file = assert(io.open(path, "w"))
        file:close()
        return true, url
      end

      cb_calls = 0
      instance = Glu(package_name)
    end)

    after_each(function()
      _G.tempTimer = real_tempTimer
      _G.downloadFile = real_downloadFile
      _G.installPackage = real_installPackage

      raiseEvent("sysUninstall", package_name)
      raiseEvent("sysUninstall", other_package_name)
    end)

    it("should remove the handlers of a running queue", function()
      local dq = new_queue(instance)
      local handler_name = dq.handler_name
      dq.start()
      assert.are.equal(3, count_handlers(handler_name))

      raiseEvent("sysUninstall", package_name)

      assert.are.equal(0, count_handlers(handler_name))
    end)

    it("should remove the handlers of a queue that was never started", function()
      local handler_name = new_queue(instance).handler_name

      raiseEvent("sysUninstall", package_name)

      assert.are.equal(0, count_handlers(handler_name))
    end)

    it("should end every queue the instance is running", function()
      local a = new_queue(instance)
      local b = new_queue(instance)
      a.start()
      b.start()

      raiseEvent("sysUninstall", package_name)

      assert.is_nil(a.queue)
      assert.is_nil(b.queue)
    end)

    it("should remove the temporary download", function()
      local dq = new_queue(instance)
      dq.start()
      local target = dq.current.target
      assert.is_truthy(lfs.attributes(target))

      raiseEvent("sysUninstall", package_name)

      assert.is_nil(lfs.attributes(target))
    end)

    it("should cancel the download timeout", function()
      local killed
      local real_killTimer = _G.killTimer
      finally(function() _G.killTimer = real_killTimer end)
      _G.killTimer = function(id)
        killed = id
        return real_killTimer(id)
      end

      local dq = new_queue(instance, 60)
      dq.start()
      local timer = dq.current.timer

      raiseEvent("sysUninstall", package_name)

      assert.is_truthy(timer)
      assert.are.equal(timer, killed)
    end)

    it("should not call the callback", function()
      new_queue(instance).start()

      raiseEvent("sysUninstall", package_name)

      assert.are.equal(0, cb_calls)
    end)

    it("should drop the step waiting to run after an install", function()
      local downloads = 0
      local waiting
      local download = _G.downloadFile
      _G.downloadFile = function(path, url)
        downloads = downloads + 1
        return download(path, url)
      end
      _G.tempTimer = function(time, code)
        if time == 1 then waiting = code end
        return 1
      end

      local dq = new_queue(instance, nil, {
        {name = "FakePkgInstalled", url = "https://example.com/installed.mpackage"},
        {name = "FakePkgNext", url = "https://example.com/next.mpackage"},
      })
      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgInstalled", dq.current.target)
      assert.are.equal("function", type(waiting))

      raiseEvent("sysUninstall", package_name)

      assert.has_no.errors(waiting)
      assert.are.equal(1, downloads)
      assert.are.equal(0, cb_calls)
    end)

    it("should let the package's own uninstall handler call clean_up", function()
      local dq = new_queue(instance)
      dq.start()

      raiseEvent("sysUninstall", package_name)

      assert.has_no.errors(dq.clean_up)
    end)

    it("should leave the queues of another package's instance running", function()
      local other = Glu(other_package_name)
      local dq = new_queue(instance)
      local other_dq = new_queue(other)
      local other_handler_name = other_dq.handler_name
      dq.start()
      other_dq.start()

      raiseEvent("sysUninstall", package_name)

      assert.is_not_nil(other_dq.queue)
      assert.are.equal(3, count_handlers(other_handler_name))

      -- The survivor still works, and still recognises its own download.
      raiseEvent("sysDownloadDone", other_dq.current.target, 1024, {})
      raiseEvent("sysInstallPackage", "FakePkgUninstall", other_dq.current.target)
      assert.is_nil(other_dq.current)
    end)

    it("should leave its queues running when another package is uninstalled", function()
      local dq = new_queue(instance)
      local handler_name = dq.handler_name
      dq.start()

      raiseEvent("sysUninstall", other_package_name)

      assert.is_not_nil(dq.queue)
      assert.are.equal(3, count_handlers(handler_name))
    end)

    it("should stop tracking a queue once it ends", function()
      local dq = new_queue(instance)

      dq.clean_up()

      assert.is_nil(instance.dependency_queue.installs[dq])
    end)
  end)

  describe("start", function()
    it("should return nil after clean_up", function()
      local result = g.dependency_queue.new_dependency_queue(
        {{name = "__glu_test_fake_start_nil__", url = "https://example.com/fake"}},
        function() end
      )

      result.clean_up()
      local start_result = result.start()

      assert.is_nil(start_result)
    end)

    it("should return error message after clean_up", function()
      local result = g.dependency_queue.new_dependency_queue(
        {{name = "__glu_test_fake_start_err__", url = "https://example.com/fake"}},
        function() end
      )

      result.clean_up()
      local _, err = result.start()

      assert.are.equal("Queue not found", err)
    end)
  end)
end)
