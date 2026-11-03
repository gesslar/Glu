describe("http module", function()
  local g
  local real_getHTTP, real_postHTTP, real_putHTTP, real_deleteHTTP, real_customHTTP

  setup(function()
    g = Glu("Glu")
  end)

  before_each(function()
    -- Save real HTTP functions
    real_getHTTP = _G.getHTTP
    real_postHTTP = _G.postHTTP
    real_putHTTP = _G.putHTTP
    real_deleteHTTP = _G.deleteHTTP
    real_customHTTP = _G.customHTTP

    -- Mock HTTP functions with Mudlet's signatures. Each fires its done event from a timer.
    _G.getHTTP = function(url, headers)
      tempTimer(0, function()
        raiseEvent("sysGetHttpDone", url, "response data", {})
      end)
      return true, url
    end

    _G.postHTTP = function(data, url, headers)
      tempTimer(0, function()
        raiseEvent("sysPostHttpDone", url, "post response", {})
      end)
      return true, url
    end

    _G.putHTTP = function(data, url, headers)
      tempTimer(0, function()
        raiseEvent("sysPutHttpDone", url, "put response", {})
      end)
      return true, url
    end

    _G.deleteHTTP = function(url, headers)
      tempTimer(0, function()
        raiseEvent("sysDeleteHttpDone", url, "delete response", {})
      end)
      return true, url
    end

    _G.customHTTP = function(method, data, url, headers)
      tempTimer(0, function()
        raiseEvent("sysCustomHttpDone", url, "custom response", method, {})
      end)
      return true, url
    end
  end)

  after_each(function()
    _G.getHTTP = real_getHTTP
    _G.postHTTP = real_postHTTP
    _G.putHTTP = real_putHTTP
    _G.deleteHTTP = real_deleteHTTP
    _G.customHTTP = real_customHTTP
  end)

  -- ========================================================================
  -- http_types
  -- ========================================================================

  describe("http_types", function()
    it("should contain standard HTTP methods", function()
      assert.are.same({"GET", "PUT", "POST", "DELETE"}, g.http.http_types)
    end)
  end)

  -- ========================================================================
  -- get
  -- ========================================================================

  describe("get", function()
    it("should set method to GET and return a request", function()
      local request = g.http.get({
        url = "http://example.com/test"
      }, function() end)
      assert.is_truthy(request)
      assert.is_truthy(request.id)
    end)

    it("should set method to GET regardless of options", function()
      local request = g.http.get({
        url = "http://example.com/test",
        method = "POST" -- should be overridden
      }, function() end)
      assert.are.equal("get", request.method_lc)
    end)
  end)

  -- ========================================================================
  -- post
  -- ========================================================================

  describe("post", function()
    it("should set method to POST", function()
      local request = g.http.post({
        url = "http://example.com/test"
      }, function() end)
      assert.are.equal("post", request.method_lc)
    end)
  end)

  -- ========================================================================
  -- put
  -- ========================================================================

  describe("put", function()
    it("should set method to PUT", function()
      local request = g.http.put({
        url = "http://example.com/test"
      }, function() end)
      assert.are.equal("put", request.method_lc)
    end)
  end)

  -- ========================================================================
  -- delete
  -- ========================================================================

  describe("delete", function()
    it("should set method to DELETE", function()
      local request = g.http.delete({
        url = "http://example.com/test"
      }, function() end)
      assert.are.equal("delete", request.method_lc)
    end)
  end)

  -- ========================================================================
  -- request
  -- ========================================================================

  describe("request", function()
    it("should create a request with custom method", function()
      local request = g.http.request({
        url = "http://example.com/test",
        method = "PATCH"
      }, function() end)
      assert.is_truthy(request)
      assert.is_true(request.custom)
      assert.are.equal("custom", request.method_lc)
    end)

    it("should uppercase the method", function()
      local request = g.http.request({
        url = "http://example.com/test",
        method = "get"
      }, function() end)
      assert.are.equal("get", request.method_lc)
    end)

    it("should initialize headers to empty table if not provided", function()
      local request = g.http.get({
        url = "http://example.com/test"
      }, function() end)
      assert.are.same({}, request.headers)
    end)

    it("should preserve provided headers", function()
      local headers = {["Content-Type"] = "application/json"}
      local request = g.http.get({
        url = "http://example.com/test",
        headers = headers
      }, function() end)
      assert.are.equal("application/json", request.headers["Content-Type"])
    end)

    it("should error on missing url", function()
      assert.has_error(function()
        g.http.get({}, function() end)
      end)
    end)

    it("should error on invalid url", function()
      assert.has_error(function()
        g.http.get({url = "not a url"}, function() end)
      end)
    end)

    it("should error on missing callback", function()
      assert.has_error(function()
        g.http.get({url = "http://example.com/test"})
      end)
    end)

    it("should error on non-table options", function()
      assert.has_error(function()
        g.http.request("http://example.com", function() end)
      end)
    end)
  end)

  -- ========================================================================
  -- find_request / delete_request
  -- ========================================================================

  describe("find_request", function()
    it("should find a request by id", function()
      local request = g.http.get({
        url = "http://example.com/test"
      }, function() end)
      local found = g.http.find_request(request.id)
      assert.are.equal(request, found)
    end)

    it("should return nil for unknown id", function()
      local found = g.http.find_request("nonexistent-id")
      assert.is_nil(found)
    end)
  end)

  describe("delete_request", function()
    it("should remove a request by id", function()
      local request = g.http.get({
        url = "http://example.com/test"
      }, function() end)
      local id = request.id
      g.http.delete_request(id)
      assert.is_nil(g.http.find_request(id))
    end)

    it("should not error on unknown id", function()
      assert.has_no.errors(function()
        g.http.delete_request("nonexistent-id")
      end)
    end)
  end)

  -- ========================================================================
  -- download
  -- ========================================================================

  describe("download", function()
    it("should default method to GET", function()
      local request = g.http.download({
        url = "http://example.com/file.txt",
        saveTo = "/tmp/test.txt"
      }, function() end)
      assert.are.equal("get", request.method_lc)
    end)

    it("should error when saveTo is missing", function()
      assert.has_error(function()
        g.http.download({
          url = "http://example.com/file.txt"
        }, function() end)
      end)
    end)
  end)

  -- ========================================================================
  -- Callback execution (async — tested via event system)
  -- ========================================================================

  describe("callback", function()
    it("should call callback when done event fires", function()
      local response_received
      local captured_url

      -- Override getHTTP to capture the URL and do nothing
      _G.getHTTP = function(url, headers)
        captured_url = url
        return true, url
      end

      local request = g.http.get({
        url = "http://example.com/test"
      }, function(response)
        response_received = response
      end)

      -- Manually fire the done event as Mudlet would
      raiseEvent("sysGetHttpDone", "http://example.com/test", "response body", {})

      assert.is_truthy(response_received)
      assert.is_truthy(response_received.result)
      assert.are.equal("http://example.com/test", captured_url)
    end)
  end)
end)
