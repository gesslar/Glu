describe("timer module", function()
  local g
  local real_tempTimer
  local real_killTimer
  local timer_id_counter
  local timer_callbacks
  local killed_timers

  setup(function()
    g = Glu("Glu")
  end)

  before_each(function()
    real_tempTimer = _G.tempTimer
    real_killTimer = _G.killTimer
    timer_id_counter = 0
    timer_callbacks = {}
    killed_timers = {}

    -- Mock tempTimer: records the callback and returns an id
    _G.tempTimer = function(delay, callback)
      timer_id_counter = timer_id_counter + 1
      local id = timer_id_counter
      timer_callbacks[id] = {delay = delay, callback = callback}
      return id
    end

    -- Mock killTimer: records that the timer was killed
    _G.killTimer = function(id)
      killed_timers[id] = true
      return true
    end
  end)

  after_each(function()
    _G.tempTimer = real_tempTimer
    _G.killTimer = real_killTimer
    -- Clean up any multi_timers state
    g.timer.multi_timers = {}
  end)

  -- Helper: fire a timer callback by id
  local function fire_timer(id)
    local t = timer_callbacks[id]
    if t and t.callback then
      t.callback()
    end
  end

  describe("multi", function()
    it("should create a multi timer and return true", function()
      local ok = g.timer.multi("test", {
        {delay = 1, func = function() end},
      })
      assert.is_true(ok)
    end)

    it("should record the timer in multi_timers", function()
      g.timer.multi("test", {
        {delay = 1, func = function() end},
      })
      assert.is_truthy(g.timer.multi_timers["test"])
    end)

    it("should store the timer id", function()
      g.timer.multi("test", {
        {delay = 1, func = function() end},
      })
      assert.are.equal(1, g.timer.multi_timers["test"].id)
    end)

    it("should apply uniform delay when provided", function()
      g.timer.multi("test", {
        {func = function() end},
        {func = function() end},
      }, 5)

      -- The first timer should be created with delay=5
      assert.are.equal(5, timer_callbacks[1].delay)
    end)

    it("should use per-step delay from def", function()
      g.timer.multi("test", {
        {delay = 2, func = function() end},
        {delay = 3, func = function() end},
      })

      assert.are.equal(2, timer_callbacks[1].delay)
    end)

    it("should execute first function when timer fires", function()
      local called = false
      g.timer.multi("test", {
        {delay = 1, func = function() called = true end},
      })

      fire_timer(1)
      assert.is_true(called)
    end)

    it("should execute functions in sequence", function()
      local order = {}
      g.timer.multi("test", {
        {delay = 1, func = function() table.insert(order, "first") end},
        {delay = 1, func = function() table.insert(order, "second") end},
        {delay = 1, func = function() table.insert(order, "third") end},
      })

      -- Fire first timer
      fire_timer(1)
      assert.are.same({"first"}, order)

      -- Fire second timer (created by the chaining)
      fire_timer(2)
      assert.are.same({"first", "second"}, order)

      -- Fire third timer
      fire_timer(3)
      assert.are.same({"first", "second", "third"}, order)
    end)

    it("should clean up after last function executes", function()
      g.timer.multi("test", {
        {delay = 1, func = function() end},
      })

      fire_timer(1)
      assert.is_nil(g.timer.multi_timers["test"])
    end)

    it("should error on non-string name", function()
      assert.has_error(function()
        g.timer.multi(123, {{delay = 1, func = function() end}})
      end)
    end)

    it("should error on empty def table", function()
      assert.has_error(function()
        g.timer.multi("test", {})
      end)
    end)

    it("should return false when tempTimer fails", function()
      _G.tempTimer = function() return -1, "unable to compile" end

      local ok, err = g.timer.multi("test", {
        {delay = 1, func = function() end},
      })
      assert.is_false(ok)
      assert.is_truthy(err)
    end)
  end)

  describe("kill_multi", function()
    it("should kill an existing multi timer", function()
      g.timer.multi("test", {
        {delay = 1, func = function() end},
      })

      local result = g.timer.kill_multi("test")
      assert.is_true(result)
    end)

    it("should remove the timer from multi_timers", function()
      g.timer.multi("test", {
        {delay = 1, func = function() end},
      })

      g.timer.kill_multi("test")
      assert.is_nil(g.timer.multi_timers["test"])
    end)

    it("should call killTimer with the correct id", function()
      g.timer.multi("test", {
        {delay = 1, func = function() end},
      })

      g.timer.kill_multi("test")
      assert.is_true(killed_timers[1])
    end)

    it("should return nil for non-existent timer", function()
      local result = g.timer.kill_multi("nonexistent")
      assert.is_nil(result)
    end)

    it("should error on non-string name", function()
      assert.has_error(function()
        g.timer.kill_multi(123)
      end)
    end)
  end)
end)
