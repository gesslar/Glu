describe("http_response module", function()
  local g
  local http_response

  setup(function()
    g = Glu("Glu")
    -- The glass constructor, as http_request obtains it via ___.get_glass
    http_response = Glu.get_glass("http_response")
  end)

  it("should store the id from the response", function()
    local r = http_response({id = "abc-123", url = "http://x", data = "body", server = {}}, g.http)
    assert.are.equal("abc-123", r.id)
  end)

  it("should store the full response as result", function()
    local data = {id = "abc-123", url = "http://x", data = "body", server = {}}
    local r = http_response(data, g.http)
    assert.are.same(data, r.result)
  end)

  it("should keep a reference to the same response table", function()
    local data = {id = "ref", url = "http://x"}
    local r = http_response(data, g.http)
    assert.are.equal(data, r.result)
  end)

  it("should expose result fields for a done-shaped response", function()
    local r = http_response({id = "1", url = "http://x", data = "payload", server = {code = 200}}, g.http)
    assert.are.equal("http://x", r.result.url)
    assert.are.equal("payload", r.result.data)
    assert.are.equal(200, r.result.server.code)
  end)

  it("should expose result fields for an error-shaped response", function()
    local r = http_response({id = "2", error = "boom", url = "http://x", server = {}}, g.http)
    assert.are.equal("boom", r.result.error)
    assert.are.equal("http://x", r.result.url)
  end)

  it("should handle a response with no id", function()
    local r = http_response({url = "http://x"}, g.http)
    assert.is_nil(r.id)
  end)
end)
