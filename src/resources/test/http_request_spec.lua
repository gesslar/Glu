describe("http_request module", function()
  local g
  local real_getHTTP, real_postHTTP, real_putHTTP, real_deleteHTTP, real_customHTTP
  local real_register
  local registered_names

  setup(function()
    g = Glu("Glu")
  end)

  before_each(function()
    -- Fresh owner each test so the request registry is isolated
    g = Glu("Glu")

    real_getHTTP = _G.getHTTP
    real_postHTTP = _G.postHTTP
    real_putHTTP = _G.putHTTP
    real_deleteHTTP = _G.deleteHTTP
    real_customHTTP = _G.customHTTP

    -- Silent transports by default; tests fire events manually when needed
    _G.getHTTP = function(url) return true, url end
    _G.postHTTP = function(_, url) return true, url end
    _G.putHTTP = function(_, url) return true, url end
    _G.deleteHTTP = function(url) return true, url end
    _G.customHTTP = function(_, _, url) return true, url end

    -- Record every named handler so we can tear them all down afterwards,
    -- otherwise un-fired requests leave handlers that cross-talk into later
    -- event-firing tests.
    real_register = _G.registerNamedEventHandler
    registered_names = {}
    _G.registerNamedEventHandler = function(name, ...)
      registered_names[name] = true
      return real_register(name, ...)
    end
  end)

  after_each(function()
    _G.registerNamedEventHandler = real_register
    for name in pairs(registered_names) do
      deleteAllNamedEventHandlers(name)
    end

    _G.getHTTP = real_getHTTP
    _G.postHTTP = real_postHTTP
    _G.putHTTP = real_putHTTP
    _G.deleteHTTP = real_deleteHTTP
    _G.customHTTP = real_customHTTP
  end)

  -- ========================================================================
  -- method classification
  -- ========================================================================

  describe("method classification", function()
    it("classifies GET as a standard, non-custom method", function()
      local r = g.http.get({url = "http://example.com/x"}, function() end)
      assert.are.equal("get", r.method_lc)
      assert.are.equal("Get", r.method_uc)
      assert.is_false(r.custom)
    end)

    it("classifies POST as a standard method", function()
      local r = g.http.post({url = "http://example.com/x"}, function() end)
      assert.are.equal("post", r.method_lc)
      assert.is_false(r.custom)
    end)

    it("classifies PUT as a standard method", function()
      local r = g.http.put({url = "http://example.com/x"}, function() end)
      assert.are.equal("put", r.method_lc)
      assert.is_false(r.custom)
    end)

    it("classifies DELETE as a standard method", function()
      local r = g.http.delete({url = "http://example.com/x"}, function() end)
      assert.are.equal("delete", r.method_lc)
      assert.is_false(r.custom)
    end)

    it("classifies an unknown method as custom", function()
      local r = g.http.request({url = "http://example.com/x", method = "PATCH"}, function() end)
      assert.are.equal("custom", r.method_lc)
      assert.are.equal("Custom", r.method_uc)
      assert.is_true(r.custom)
    end)
  end)

  -- ========================================================================
  -- transport invocation
  -- ========================================================================

  describe("transport invocation", function()
    it("calls the lowercase <method>HTTP global for standard methods", function()
      local called
      _G.getHTTP = function(url, headers) called = {url = url, headers = headers} end
      g.http.get({url = "http://example.com/x", headers = {A = "b"}}, function() end)
      assert.is_truthy(called)
      assert.are.equal("http://example.com/x", called.url)
      assert.are.equal("b", called.headers.A)
    end)

    it("passes only url and headers to get and delete", function()
      local get_count, delete_count
      _G.getHTTP = function(...) get_count = select("#", ...) end
      _G.deleteHTTP = function(...) delete_count = select("#", ...) end
      g.http.get({url = "http://example.com/x"}, function() end)
      g.http.delete({url = "http://example.com/x"}, function() end)
      assert.are.equal(2, get_count)
      assert.are.equal(2, delete_count)
    end)

    it("passes data, url and headers to post and put", function()
      for _, verb in ipairs({"post", "put"}) do
        local called
        _G[verb .. "HTTP"] = function(data, url, headers)
          called = {data = data, url = url, headers = headers}
        end
        g.http[verb]({url = "http://example.com/x", data = "payload", headers = {A = "b"}}, function() end)
        assert.are.equal("payload", called.data)
        assert.are.equal("http://example.com/x", called.url)
        assert.are.equal("b", called.headers.A)
      end
    end)

    it("sends an empty body when post has no data", function()
      local sent
      _G.postHTTP = function(data) sent = data end
      g.http.post({url = "http://example.com/x"}, function() end)
      assert.are.equal("", sent)
    end)

    it("errors when data is not a string", function()
      assert.has_error(function()
        g.http.post({url = "http://example.com/x", data = {}}, function() end)
      end)
    end)

    it("calls customHTTP with the method, data, url and headers", function()
      local called
      _G.customHTTP = function(method, data, url, headers)
        called = {method = method, data = data, url = url, headers = headers}
      end
      g.http.request({
        url = "http://example.com/x",
        method = "PATCH",
        data = "payload",
        headers = {A = "b"},
      }, function() end)
      assert.is_truthy(called)
      assert.are.equal("PATCH", called.method)
      assert.are.equal("payload", called.data)
      assert.are.equal("http://example.com/x", called.url)
      assert.are.equal("b", called.headers.A)
    end)

    -- These run Mudlet's own transports, which reject a bad signature as soon as
    -- they're called. Nothing listens on port 1, and after_each removes the
    -- handlers before the resulting error event can arrive.
    describe("against Mudlet's real functions", function()
      local unreachable = "http://localhost:1/"

      before_each(function()
        _G.getHTTP = real_getHTTP
        _G.postHTTP = real_postHTTP
        _G.putHTTP = real_putHTTP
        _G.deleteHTTP = real_deleteHTTP
        _G.customHTTP = real_customHTTP
      end)

      for _, verb in ipairs({"get", "post", "put", "delete"}) do
        it("accepts the arguments Glu sends for " .. verb, function()
          assert.has_no.errors(function()
            g.http[verb]({url = unreachable, data = "payload"}, function() end)
          end)
        end)
      end

      it("accepts the arguments Glu sends for a custom method", function()
        assert.has_no.errors(function()
          g.http.request({url = unreachable, method = "PATCH", data = "payload"}, function() end)
        end)
      end)
    end)

    it("errors when the transport global is missing", function()
      _G.getHTTP = nil
      assert.has_error(function()
        g.http.get({url = "http://example.com/x"}, function() end)
      end)
    end)

    it("registers no handlers when the transport global is missing", function()
      _G.getHTTP = nil
      assert.has_error(function()
        g.http.get({url = "http://example.com/x"}, function() end)
      end)
      assert.is_nil(next(registered_names))
    end)

    it("removes its handlers when the transport throws", function()
      _G.getHTTP = function() error("boom") end
      assert.has_error(function()
        g.http.get({url = "http://example.com/x"}, function() end)
      end)
      assert.is_truthy(next(registered_names))
      for name in pairs(registered_names) do
        assert.are.same({}, getNamedEventHandlers(name))
      end
    end)
  end)

  -- ========================================================================
  -- headers
  -- ========================================================================

  describe("headers", function()
    it("defaults headers to an empty table when omitted", function()
      local r = g.http.get({url = "http://example.com/x"}, function() end)
      assert.are.same({}, r.headers)
    end)

    it("preserves provided headers", function()
      local r = g.http.get({
        url = "http://example.com/x",
        headers = {["Content-Type"] = "application/json"}
      }, function() end)
      assert.are.equal("application/json", r.headers["Content-Type"])
    end)

    it("errors when headers is not a table", function()
      assert.has_error(function()
        g.http.get({url = "http://example.com/x", headers = "nope"}, function() end)
      end)
    end)
  end)

  -- ========================================================================
  -- id and registration
  -- ========================================================================

  describe("id and registration", function()
    it("assigns an id to the request", function()
      local r = g.http.get({url = "http://example.com/x"}, function() end)
      assert.is_truthy(r.id)
    end)

    it("registers the request with its owner", function()
      local r = g.http.get({url = "http://example.com/x"}, function() end)
      assert.are.equal(r, g.http.find_request(r.id))
    end)

    it("removes its handlers when deleted", function()
      local called = false
      local r = g.http.get({url = "http://example.com/x"}, function() called = true end)
      g.http.delete_request(r.id)
      assert.are.same({}, getNamedEventHandlers(r.id))
      raiseEvent("sysGetHttpDone", "http://example.com/x", "body", {})
      assert.is_false(called)
    end)
  end)

  -- ========================================================================
  -- done handling
  -- ========================================================================

  describe("done handling", function()
    it("invokes the callback with an http_response on a done event", function()
      local got
      local r = g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "the body", {headers = {}, cookies = {}})
      assert.is_truthy(got)
      assert.is_truthy(got.result)
      assert.are.equal(r.id, got.id)
    end)

    it("populates the response with url and data on done", function()
      local got
      g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "the body", {})
      assert.are.equal("http://example.com/x", got.result.url)
      assert.are.equal("the body", got.result.data)
    end)

    it("removes the request from its owner after done", function()
      local r = g.http.get({url = "http://example.com/x"}, function() end)
      local id = r.id
      raiseEvent("sysGetHttpDone", "http://example.com/x", "body", {})
      assert.is_nil(g.http.find_request(id))
    end)

    it("leaves request_id nil when the done event does not carry one", function()
      local got
      g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "the body", {})
      assert.is_truthy(got)
      assert.is_nil(got.result.request_id)
    end)

    it("exposes the request id Mudlet appends to a done event", function()
      _G.getHTTP = function(url) return true, url, 42 end
      local got
      local r = g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "the body", {}, 42)
      assert.is_truthy(got)
      assert.are.equal("the body", got.result.data)
      assert.are.equal(42, got.result.request_id)
      assert.are.equal(r.id, got.id)
    end)

    it("completes only the request whose id the event carries", function()
      local next_id = 0
      _G.getHTTP = function(url)
        next_id = next_id + 1
        return true, url, next_id
      end
      local first, second
      g.http.get({url = "http://example.com/same"}, function(resp) first = resp end)
      g.http.get({url = "http://example.com/same"}, function(resp) second = resp end)

      raiseEvent("sysGetHttpDone", "http://example.com/same", "second body", {}, 2)
      assert.is_nil(first)
      assert.are.equal("second body", second.result.data)

      raiseEvent("sysGetHttpDone", "http://example.com/same", "first body", {}, 1)
      assert.are.equal("first body", first.result.data)
    end)

    it("completes a redirected request whose event reports a different url", function()
      _G.getHTTP = function(url) return true, url, 7 end
      local got
      g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpDone", "http://cdn.example.com/y", "the body", {}, 7)
      assert.are.equal("http://cdn.example.com/y", got.result.url)
    end)

    it("ignores an event for another request, leaving this one tracked", function()
      _G.getHTTP = function(url) return true, url, 1 end
      local called = false
      local r = g.http.get({url = "http://example.com/x"}, function() called = true end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "not ours", {}, 99)
      assert.is_false(called)
      assert.are.equal(r, g.http.find_request(r.id))
    end)

    it("maps a custom done event around its method argument", function()
      _G.customHTTP = function(_, _, url) return true, url, 5 end
      local got
      g.http.request({url = "http://example.com/x", method = "PATCH"}, function(resp) got = resp end)
      local server = {headers = {}}
      raiseEvent("sysCustomHttpDone", "http://example.com/x", "the body", "PATCH", server, 5)
      assert.is_truthy(got)
      assert.are.equal("the body", got.result.data)
      assert.are.equal("PATCH", got.result.method)
      assert.are.equal(5, got.result.request_id)
      assert.is_table(got.result.server)
    end)

    it("maps a custom done event from a Mudlet without request ids", function()
      local got
      g.http.request({url = "http://example.com/x", method = "PATCH"}, function(resp) got = resp end)
      raiseEvent("sysCustomHttpDone", "http://example.com/x", "the body", "PATCH", {})
      assert.is_truthy(got)
      assert.are.equal("PATCH", got.result.method)
      assert.is_nil(got.result.request_id)
    end)
  end)

  -- ========================================================================
  -- error handling
  -- ========================================================================

  describe("error handling", function()
    it("populates the response with error and url on an error event", function()
      local got
      g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpError", "the error message", "http://example.com/x", {})
      assert.is_truthy(got)
      assert.are.equal("the error message", got.result.error)
      assert.are.equal("http://example.com/x", got.result.url)
    end)

    it("removes the request from its owner after an error", function()
      local r = g.http.get({url = "http://example.com/x"}, function() end)
      local id = r.id
      raiseEvent("sysGetHttpError", "boom", "http://example.com/x", {})
      assert.is_nil(g.http.find_request(id))
    end)

    it("leaves body and request_id nil when the error event does not carry them", function()
      local got
      g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpError", "boom", "http://example.com/x", {})
      assert.is_truthy(got)
      assert.is_nil(got.result.body)
      assert.is_nil(got.result.request_id)
    end)

    it("exposes the server's response body on an error event", function()
      local got
      g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpError", "boom", "http://example.com/x", {}, "not found page")
      assert.is_truthy(got)
      assert.are.equal("not found page", got.result.body)
      assert.is_nil(got.result.request_id)
    end)

    it("maps a custom error event around its method argument", function()
      _G.customHTTP = function(_, _, url) return true, url, 5 end
      local got
      g.http.request({url = "http://example.com/x", method = "PATCH"}, function(resp) got = resp end)
      raiseEvent("sysCustomHttpError", "boom", "http://example.com/x", "PATCH", {}, "not found page", 5)
      assert.is_truthy(got)
      assert.are.equal("boom", got.result.error)
      assert.are.equal("PATCH", got.result.method)
      assert.are.equal("not found page", got.result.body)
      assert.are.equal(5, got.result.request_id)
    end)

    it("exposes the request id after the body on an error event", function()
      _G.getHTTP = function(url) return true, url, 42 end
      local got
      local r = g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpError", "boom", "http://example.com/x", {}, "not found page", 42)
      assert.is_truthy(got)
      assert.are.equal("boom", got.result.error)
      assert.are.equal("not found page", got.result.body)
      assert.are.equal(42, got.result.request_id)
      assert.are.equal(r.id, got.id)
    end)
  end)

  -- ========================================================================
  -- saveTo
  -- ========================================================================

  describe("saveTo", function()
    local done_path = "/tmp/glu_http_request_spec_done.txt"
    local err_path = "/tmp/glu_http_request_spec_err.txt"

    before_each(function()
      if g.fd.file_exists(done_path) then g.fd.rmfile(done_path) end
      if g.fd.file_exists(err_path) then g.fd.rmfile(err_path) end
    end)

    after_each(function()
      if g.fd.file_exists(done_path) then g.fd.rmfile(done_path) end
      if g.fd.file_exists(err_path) then g.fd.rmfile(err_path) end
    end)

    it("writes the response body to disk on a done event", function()
      g.http.download({url = "http://example.com/x", saveTo = done_path}, function() end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "saved body", {})
      assert.is_true(g.fd.file_exists(done_path))
      assert.are.equal("saved body", g.fd.read_file(done_path))
    end)

    it("overwrites an existing file on a done event", function()
      g.fd.write_file(done_path, "old body")
      g.http.download({url = "http://example.com/x", saveTo = done_path}, function() end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "new body", {})
      assert.are.equal("new body", g.fd.read_file(done_path))
    end)

    it("does not write to disk on an error event", function()
      g.http.download({url = "http://example.com/x", saveTo = err_path}, function() end)
      raiseEvent("sysGetHttpError", "boom", "http://example.com/x", {})
      assert.is_false(g.fd.file_exists(err_path))
    end)
  end)

  -- ========================================================================
  -- package uninstall
  -- ========================================================================

  describe("when the package is uninstalled", function()
    -- sysUninstall kills the instance it names, so nothing here can use the shared one.
    local package_name = "__glu_test_http_uninstall__"
    local other_package_name = "__glu_test_http_uninstall_other__"
    local instance

    before_each(function()
      instance = Glu(package_name)
    end)

    after_each(function()
      raiseEvent("sysUninstall", package_name)
      raiseEvent("sysUninstall", other_package_name)
    end)

    it("removes the handlers of every request in flight", function()
      local get = instance.http.get({url = "http://example.com/x"}, function() end)
      local post = instance.http.post({url = "http://example.com/x"}, function() end)

      raiseEvent("sysUninstall", package_name)

      assert.are.same({}, getNamedEventHandlers(get.id))
      assert.are.same({}, getNamedEventHandlers(post.id))
    end)

    it("does not call the callback when a response arrives later", function()
      local calls = 0
      instance.http.get({url = "http://example.com/x"}, function() calls = calls + 1 end)

      raiseEvent("sysUninstall", package_name)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "body", {})

      assert.are.equal(0, calls)
    end)

    it("does not call the callback on uninstall", function()
      local calls = 0
      instance.http.get({url = "http://example.com/x"}, function() calls = calls + 1 end)

      raiseEvent("sysUninstall", package_name)

      assert.are.equal(0, calls)
    end)

    it("leaves the requests of another package's instance in flight", function()
      local other = Glu(other_package_name)
      local got
      instance.http.get({url = "http://example.com/x"}, function() end)
      local other_request = other.http.get({url = "http://example.com/y"}, function(resp) got = resp end)

      raiseEvent("sysUninstall", package_name)

      assert.are.equal(other_request, other.http.find_request(other_request.id))

      raiseEvent("sysGetHttpDone", "http://example.com/y", "body", {})
      assert.are.equal("body", got.result.data)
    end)

    it("leaves its requests in flight when another package is uninstalled", function()
      local request = instance.http.get({url = "http://example.com/x"}, function() end)

      raiseEvent("sysUninstall", other_package_name)

      assert.are.equal(request, instance.http.find_request(request.id))
      assert.is_false(table.is_empty(getNamedEventHandlers(request.id)))
    end)
  end)
end)
