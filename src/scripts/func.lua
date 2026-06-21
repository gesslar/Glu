local FuncClass = Glu.glass.register({
  name = "func",
  class_name = "FuncClass",
  dependencies = {},
  setup = function(___, self)
    --- Schedules a function to run after a delay.
    --- Wraps Mudlet's `tempTimer`, forwarding any extra arguments to the function when it fires.
    ---
    ---@param func function The function to run after the delay.
    ---@param delay number The delay in seconds before the function runs.
    ---@param ... any Additional arguments passed to the function when it runs.
    ---@returns number The timer id returned by tempTimer.
    ---@example
    --- ```lua
    --- func.delay(function() echo("hi") end, 5)
    --- ```
    function self.delay(func, delay, ...)
      ___.v.type(func, "function", 1, false)
      ___.v.type(delay, "number", 2, false)

      local args = { ... }
      ---@diagnostic disable-next-line: return-type-mismatch
      return tempTimer(delay, function()
        func(unpack(args))
      end)
    end

    --- Wraps a function with another function.
    --- Returns a new function that calls the wrapper with the original function as its first argument, followed by any arguments passed to the new function.
    ---
    ---@param func function The function to be wrapped.
    ---@param wrapper function The wrapper function, which receives `func` followed by the call arguments.
    ---@returns function The wrapped function.
    function self.wrap(func, wrapper)
      --- ```lua
      --- local becho = function.wrap(cecho, function(func, text)
      ---   func("<b>{text}</b>")
      --- end)
      ---
      --- becho("Hello, world!")
      --- -- <b>Hello, world!</b>
      --- ```
      ___.v.type(func, "function", 1, false)
      ___.v.type(wrapper, "function", 2, false)

      return function(...)
        return wrapper(func, ...)
      end
    end

    --- Repeatedly runs a function on an interval.
    --- Runs the function up to `times` times, waiting `interval` seconds between each run, forwarding any extra arguments to the function on each run.
    ---
    ---@param func function The function to run repeatedly.
    ---@param interval number The interval in seconds between runs. Defaults to 1.
    ---@param times number The number of times to run the function. Defaults to 1.
    ---@param ... any Additional arguments passed to the function on each run.
    ---@returns nil
    ---@example
    --- ```lua
    --- func.repeater(function() echo("tick\n") end, 2, 3)
    --- ```
    function self.repeater(func, interval, times, ...)
      ___.v.type(func, "function", 1, false)
      ___.v.type(interval, "number", 2, true)
      ___.v.type(times, "number", 3, true)

      interval = interval or 1
      times = times or 1

      local args = { ... }
      local count = 0
      local function _repeat()
        if count < times then
          func(unpack(args))
          count = count + 1
          tempTimer(interval, _repeat)
        end
      end
      _repeat()
    end
  end
})
