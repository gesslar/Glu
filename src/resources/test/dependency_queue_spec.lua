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

      -- Mock tempTimer to execute callback immediately (same pattern as Mudlet's own tests)
      _G.tempTimer = function(time, code)
        if type(code) == "function" then
          code()
        elseif type(code) == "string" then
          loadstring(code)()
        end
      end

      -- Mock installPackage to do nothing — we fire sysInstall manually
      _G.installPackage = function() end

      -- Mock downloadFile to do nothing — we fire sysDownloadDone/Error manually
      _G.downloadFile = function() end
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

    it("should complete when sysInstall fires for the package", function()
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

      -- The download lands, then Mudlet fires sysInstall once installed
      raiseEvent("sysDownloadDone", dq.current.target)
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

      -- Mudlet fires sysDownloadError(error, local_file, url) for the file we chose
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/fake.mpackage")

      assert.is_false(cb_success)
      assert.is_truthy(cb_message)
    end)

    it("should install from the downloaded file when sysDownloadDone fires", function()
      local installed_from = nil
      _G.installPackage = function(path) installed_from = path end

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgDone", url = "https://example.com/FakePkgDone.mpackage"}},
        function() end
      )

      dq.start()

      local target = dq.current.target
      raiseEvent("sysDownloadDone", target)

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
      raiseEvent("sysDownloadDone", dq.current.target)
      raiseEvent("sysInstallPackage", "FakePkgA", dq.current.target)
      -- Second package downloads, then installs
      raiseEvent("sysDownloadDone", dq.current.target)
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

    before_each(function()
      real_installPackage = _G.installPackage
      real_tempTimer = _G.tempTimer
      real_downloadFile = _G.downloadFile

      _G.tempTimer = function(time, code)
        if type(code) == "function" then
          code()
        elseif type(code) == "string" then
          loadstring(code)()
        end
      end

      _G.installPackage = function() end
      _G.downloadFile = function() end
    end)

    after_each(function()
      _G.installPackage = real_installPackage
      _G.tempTimer = real_tempTimer
      _G.downloadFile = real_downloadFile
    end)

    it("should ignore sysInstall for non-matching package names", function()
      local cb_success = nil

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgX", url = "https://example.com/x"}},
        function(success, message)
          cb_success = success
        end
      )

      dq.start()
      raiseEvent("sysDownloadDone", dq.current.target)

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
        "https://example.com/first")

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
      raiseEvent("sysDownloadDone", dq.current.target)
      raiseEvent("sysInstallPackage", "FakePkgAlpha", dq.current.target)

      -- Reset to check second callback
      cb_success = nil
      cb_message = nil

      -- Second package fails; current now points at the second download
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/beta")

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
      raiseEvent("sysDownloadDone", dq.current.target)
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
        "https://elsewhere.example.com/theirs.mpackage")

      assert.is_nil(cb_success)
      assert.is_not_nil(dq.handler_name)
      assert.is_not_nil(dq.queue)

      -- Our own download and install still complete normally afterwards
      raiseEvent("sysDownloadDone", dq.current.target)
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
        "https://elsewhere.example.com/same.mpackage")

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
        "https://cdn.example.net/asset/5dd0c819-e4ee-447e-b18f-24a7b5ed17fe?sig=abc")

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
      raiseEvent("sysDownloadDone", target)
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
      _G.installPackage = function() installed = true end

      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgOther", url = "https://example.com/other.mpackage"}},
        function() end
      )

      dq.start()

      raiseEvent("sysDownloadDone", "/tmp/not-ours.mpackage")

      assert.is_false(installed)
      dq.clean_up()
    end)

    it("should clean up event handlers after download error", function()
      local dq = g.dependency_queue.new_dependency_queue(
        {{name = "FakePkgErrClean", url = "https://example.com/errclean"}},
        function() end
      )

      dq.start()
      raiseEvent("sysDownloadError", "404 not found", dq.current.target,
        "https://example.com/errclean")

      assert.is_nil(dq.handler_name)
      assert.is_nil(dq.queue)
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
