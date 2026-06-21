local TimerClass = Glu.glass.register({
  name = "timer",
  class_name = "TimerClass",
  dependencies = { "table" },
  call = "new_multi_timer",
  setup = function(___, self)

    self.multi_timers = {}

    local function perform_multi_timer_function(name)
      local timer_function = self.multi_timers[name]
      if not timer_function then
        return false, "multi timer with name " .. name .. " does not exist"
      end

      local defs = timer_function.def
      local def = defs[1]
      local ok, result = pcall(def.func, def.args)

      if not ok then
        return false, "error in multi timer with name " .. name .. ": " .. result
      end

      table.remove(defs, 1)
      if #defs > 0 then
        local result2 = ___.timer.multi(name, defs)
        if not result2 then
          return false, "error in multi timer with name " .. name .. ": " .. result2
        end
      else
        ___.timer.kill_multi(name)
      end

      return true
    end

    --- Creates nested timers and returns true if successful.
    ---@param name string The name of the multi timer.
    ---@param def table The definition of the multi timer.
    ---@param delay number The delay between each timer.
    ---@return boolean ok True if the multi timer was created, errors out if not.
    ---@example
    --- ```lua
    --- -- At intervals of 5 seconds, print "hi", "there", "you", "amazing", and
    --- -- "developer"
    --- timer.multi("Greetings", {
    ---   { func = function() echo("hi\n") end },
    ---   { func = function() echo("there\n") end },
    ---   { func = function() echo("you\n") end },
    ---   { func = function() echo("amazing\n") end },
    ---   { func = function() echo("developer\n") end },
    --- }, 5)
    ---
    --- -- After 1s, print "hi", after 3s, print "there", after 6s, print "you",
    --- -- after 10s, print "amazing", and after 15s, print "developer"
    --- timer.multi("Greetings", {
    ---   { delay = 1, func = function() echo("hi\n") end },
    ---   { delay = 2, func = function() echo("there\n") end },
    ---   { delay = 3, func = function() echo("you\n") end },
    ---   { delay = 4, func = function() echo("amazing\n") end },
    ---   { delay = 5, func = function() echo("developer\n") end },
    --- })
    --- ```
    function self.multi(name, def, delay)
      ___.v.type(name, "string", 1, false)
      ___.v.not_empty(def, 2, false)
      ___.v.type(delay, "number", 3, true)

      if delay then
        def = ___.table.map(def, function(_, element)
          element.delay = delay
          return element
        end)
      end

      -- Record the initial information
      self.multi_timers[name] = { def = def }

      local timer_id = tempTimer(def[1].delay, function()
        perform_multi_timer_function(name)
      end)

      if not timer_id then
        ___.timer.kill_multi(name)
        return false, "error creating multi timer with name " .. name
      end

      -- Record the timer id
      self.multi_timers[name].id = timer_id

      return true
    end

    --- Kills a multi timer by name.
    ---@param name string The name of the multi timer.
    ---@return boolean|nil killed True if the multi timer was killed, nil if it doesn't exist.
    ---@example
    --- ```lua
    --- timer.kill_multi("Greetings")
    --- ```
    function self.kill_multi(name)
      ___.v.type(name, "string", 1, false)

      local timer_function = self.multi_timers[name]
      if not timer_function then return nil end

      self.multi_timers[name] = nil
      local id = timer_function.id

      if id then
        return killTimer(id)
      end

      return true
    end
  end
})
