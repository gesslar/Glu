local TryClass = Glu.glass.register({
  class_name = "TryClass",
  name = "try",
  extends = nil,
  call = "clone",
  setup = function(___, self, opts)
    local result = {
      try = nil,
      catch = nil,
      finally = nil,
      result = nil
    }

    --- Starts a new try chain by running the given function under pcall.
    --- Creates a fresh try object and immediately runs `try` on it, recording
    --- whether the function succeeded or errored.
    ---
    ---@param f function The function to execute.
    ---@param ... any Arguments passed to the function.
    ---@return object try The new try object for chaining.
    ---@example
    --- ```lua
    --- try.clone(function() error("boom") end):catch(function(e) end)
    --- ```
    function self.clone(f, ...)
      local glass = ___.get_glass("try")
      assert(glass, "TryClass not found")
      local try = glass(opts, self)
      return try.try(f, ...)
    end

    -- first, let's try to execute the function
    --- Runs the given function under pcall and records the result.
    --- Stores success state, the returned value or error, and updates the try
    --- object's `result` and `caught` fields.
    ---
    ---@param f function The function to execute.
    ---@param ... any Arguments passed to the function.
    ---@return object self The try object for chaining.
    ---@example
    --- ```lua
    --- try.try(function() return 42 end):catch(function(e) end)
    --- ```
    function self.try(f, ...)
      local success, try_result = pcall(f, ...)
      if success then
        result.try = {
          success = true,
          error = nil,
          result = try_result,
          caught = false
        }
        result.result = try_result
      else
        result.try = {
          success = false,
          error = try_result,
          result = nil,
          caught = true
        }
        result.result = nil
      end

      self.result = result
      self.caught = not success

      return self
    end

    --- Runs the given handler with the try result, capturing any error.
    --- The handler receives the recorded try outcome. Its own success or failure
    --- is stored in the catch result.
    ---
    ---@param f function The handler to run with the try result.
    ---@return object self The try object for chaining.
    ---@example
    --- ```lua
    --- try.clone(function() error("boom") end):catch(function(e) print(e.error) end)
    --- ```
    function self.catch(f)
      local success, catch_result = pcall(f, result.try)
      if success then
        result.catch = {
          success = true,
          error = nil,
          result = nil
        }
      else
        result.catch = {
          success = false,
          error = catch_result,
          result = nil
        }
      end

      self.result = result
      return self
    end

    --- Always runs the given function, regardless of success or failure.
    --- The function receives the full result. If the finally block itself errors,
    --- that error is raised.
    ---
    ---@param f function The function to always run.
    ---@return object self The try object for chaining.
    ---@example
    --- ```lua
    --- try.clone(function() error("boom") end):finally(function(r) end)
    --- ```
    function self.finally(f)
      -- Pass both success and error information to finally block
      local success, finally_result = pcall(f, result)

      -- If finally block itself errors, we should probably handle that
      if not success then
        error("Error in finally block: " .. finally_result)
      end
      self.result = result
      return self
    end
  end
})
