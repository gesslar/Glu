local FuncClass = Glu.glass.register({
  name = "func",
  class_name = "FuncClass",
  dependencies = {},
  setup = function(___, self)
    function self.delay(func, delay, ...)
      ___.v.type(func, "function", 1, false)
      ___.v.type(delay, "number", 2, false)

      local args = { ... }
      ---@diagnostic disable-next-line: return-type-mismatch
      return tempTimer(delay, function()
        func(unpack(args))
      end)
    end

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
