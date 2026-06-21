local HttpClass = Glu.glass.register({
  name = "http",
  class_name = "HttpClass",
  dependencies = { "table" },
  setup = function(___, self)
    local function validate_options(options)
      ___.v.type(options, "table", 1, false)
      ___.v.not_empty(options, 1, false)
      ___.v.type(options.method, "string", 2, false)
      ___.v.regex(options.url, ___.regex.http_url, 1, false)
      ___.v.type(options.callback, "function", 1, false)
    end

    self.http_types = { "GET", "PUT", "POST", "DELETE" }

    local requests = {}

    --- Downloads a file from the given URL and saves it to the specified path.
    --- You may certainly also use the `get` or `request` methods to download a
    --- file, however, this is a bit more convenient as it does some checking
    --- for you.
    ---
    ---@param options table The options for the request.
    ---@param cb function The callback function.
    ---@returns table The HTTP request object.
    ---@example
    --- ```lua
    --- http.download({
    ---   url = "http://example.com/file.txt",
    ---   saveTo = "path/to/file.txt"
    --- }, function(response) end)
    --- ```
    function self.download(options, cb)
      options.method = options.method or "GET"
      ___.v.type(options.saveTo, "string", 1, false)
      return self.request(options, cb)
    end

    --- Makes a GET request to the given URL.
    ---
    --- The options table may consist of the following keys:
    ---
    --- - `url` (`string`) - The URL to request.
    --- - `headers` (`table`) - The headers to send with the request.
    ---
    ---@param options table The options for the request.
    ---@param cb function The callback function.
    ---@returns table The HTTP request object.
    ---@example
    --- ```lua
    --- http.get({
    ---   url = "http://example.com/file.txt"
    --- }, function(response) end)
    --- ```
    function self.get(options, cb)
      options.method = "GET"
      return self.request(options, cb)
    end

    --- Makes a POST request to the given URL.
    ---
    --- The options table may consist of the following keys:
    ---
    --- - `url` (`string`) - The URL to request.
    --- - `headers` (`table`) - The headers to send with the request.
    ---
    ---@param options table The options for the request.
    ---@param cb function The callback function.
    ---@returns table The HTTP request object.
    ---@example
    --- ```lua
    --- http.post({
    ---   url = "http://example.com/file.txt"
    --- }, function(response) end)
    --- ```
    function self.post(options, cb)
      options.method = "POST"
      return self.request(options, cb)
    end

    --- Makes a PUT request to the given URL.
    ---
    --- The options table may consist of the following keys:
    ---
    --- - `url` (`string`) - The URL to request.
    --- - `headers` (`table`) - The headers to send with the request.
    ---
    ---@param options table The options for the request.
    ---@param cb function The callback function.
    ---@returns table The HTTP request object.
    ---@example
    --- ```lua
    --- http.put({
    ---   url = "http://example.com/file.txt"
    --- }, function(response) end)
    --- ```
    function self.put(options, cb)
      options.method = "PUT"
      return self.request(options, cb)
    end

    --- Makes a DELETE request to the given URL.
    ---
    --- The options table may consist of the following keys:
    ---
    --- - `url` (`string`) - The URL to request.
    --- - `headers` (`table`) - The headers to send with the request.
    ---
    ---@param options table The options for the request.
    ---@param cb function The callback function.
    ---@returns table The HTTP request object.
    ---@example
    --- ```lua
    --- http.delete({
    ---   url = "http://example.com/file.txt"
    --- }, function(response) end)
    --- ```
    function self.delete(options, cb)
      options.method = "DELETE"
      return self.request(options, cb)
    end

    --- Makes a request to the given URL. Use this option for any HTTP method
    --- that is not: `GET`, `POST`, `PUT`, or `DELETE`.
    ---
    --- The options table may consist of the following keys:
    ---
    --- - `url` (`string`) - The URL to request.
    --- - `method` (`string`) - The HTTP method to use.
    --- - `headers` (`table`) - The headers to send with the request.
    ---
    ---@param options table The options for the request.
    ---@param cb function The callback function.
    ---@returns table The HTTP request object.
    ---@example
    --- ```lua
    --- http.request({
    ---   url = "http://example.com/file.txt"
    --- }, function(response) end)
    --- ```
    function self.request(options, cb)
      ___.v.type(options, "table", 1, false)
      ___.v.not_empty(options, 1, false)

      options.callback = options.callback or cb

      validate_options(options)

      -- upper case the method
      options.method = string.upper(options.method)

      -- Get a new http request object
      local gl = ___.get_glass("http_request")
      local request = gl(options, self).execute()
      table.insert(requests, request)
      return request
    end

    --- Removes a tracked HTTP request from the request list by its id.
    ---
    ---@param id string The id of the request to remove.
    ---@returns nil Nothing.
    function self.delete_request(id)
      for i = 1, #requests do
        if requests[i].id == id then
          table.remove(requests, i)
          break
        end
      end
    end

    --- Looks up a tracked HTTP request by its id.
    ---
    ---@param id string The id of the request to find.
    ---@returns table|nil The matching request, or nil if none is found.
    function self.find_request(id)
      for _, request in ipairs(requests) do
        if request.id == id then
          return request
        end
      end
      return nil
    end
  end
})
