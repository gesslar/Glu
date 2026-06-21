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
    _G.getHTTP = function() end
    _G.postHTTP = function() end
    _G.putHTTP = function() end
    _G.deleteHTTP = function() end
    _G.customHTTP = function() end

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

    it("passes only url and headers to a standard transport", function()
      local arg_count
      _G.postHTTP = function(...) arg_count = select("#", ...) end
      g.http.post({url = "http://example.com/x"}, function() end)
      assert.are.equal(2, arg_count)
    end)

    it("calls customHTTP with the method first for custom methods", function()
      local called
      _G.customHTTP = function(method, url, headers)
        called = {method = method, url = url, headers = headers}
      end
      g.http.request({url = "http://example.com/x", method = "PATCH"}, function() end)
      assert.is_truthy(called)
      assert.are.equal("PATCH", called.method)
      assert.are.equal("http://example.com/x", called.url)
    end)

    it("errors when the transport global is missing", function()
      _G.getHTTP = nil
      assert.has_error(function()
        g.http.get({url = "http://example.com/x"}, function() end)
      end)
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
  end)

  -- ========================================================================
  -- done handling
  -- ========================================================================

  describe("done handling", function()
    it("invokes the callback with an http_response on a done event", function()
      local got
      local r = g.http.get({url = "http://example.com/x"}, function(resp) got = resp end)
      raiseEvent("sysGetHttpDone", "http://example.com/x", "the body", {code = 200})
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

    it("does not write to disk on an error event", function()
      g.http.download({url = "http://example.com/x", saveTo = err_path}, function() end)
      raiseEvent("sysGetHttpError", "boom", "http://example.com/x", {})
      assert.is_false(g.fd.file_exists(err_path))
    end)
  end)
end)
