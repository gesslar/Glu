describe("func module", function()
  local g
  local real_tempTimer
  local timer_id_counter
  local timer_callbacks

  setup(function()
    g = Glu("Glu")
  end)

  before_each(function()
    real_tempTimer = _G.tempTimer
    timer_id_counter = 0
    timer_callbacks = {}

    -- Mock tempTimer: records the callback and returns an id
    _G.tempTimer = function(delay, callback)
      timer_id_counter = timer_id_counter + 1
      local id = timer_id_counter
      timer_callbacks[id] = {delay = delay, callback = callback}
      return id
    end
  end)

  after_each(function()
    _G.tempTimer = real_tempTimer
  end)

  -- Helper: fire a recorded timer callback by id
  local function fire_timer(id)
    local t = timer_callbacks[id]
    if t and t.callback then
      t.callback()
    end
  end

  describe("delay", function()
    it("should return the timer id from tempTimer", function()
      local id = g.func.delay(function() end, 5)
      assert.are.equal(1, id)
    end)

    it("should schedule with the provided delay", function()
      g.func.delay(function() end, 7)
      assert.are.equal(7, timer_callbacks[1].delay)
    end)

    it("should not invoke the function before the timer fires", function()
      local called = false
      g.func.delay(function() called = true end, 5)
      assert.is_false(called)
    end)

    it("should invoke the function when the timer fires", function()
      local called = false
      local id = g.func.delay(function() called = true end, 5)
      fire_timer(id)
      assert.is_true(called)
    end)

    it("should forward varargs to the function when fired", function()
      local received
      local id = g.func.delay(function(...) received = {...} end, 5, "a", "b")
      fire_timer(id)
      assert.are.same({"a", "b"}, received)
    end)

    it("should forward varargs of mixed types", function()
      local received
      local tbl = {x = 1}
      local id = g.func.delay(function(...) received = {...} end, 5, 1, "two", tbl, true)
      fire_timer(id)
      assert.are.same({1, "two", tbl, true}, received)
    end)

    it("should invoke with no arguments when none are provided", function()
      local count
      local id = g.func.delay(function(...) count = select("#", ...) end, 5)
      fire_timer(id)
      assert.are.equal(0, count)
    end)

    it("should error when func is not a function", function()
      assert.has_error(function()
        g.func.delay("not a function", 5)
      end)
    end)

    it("should error when func is nil", function()
      assert.has_error(function()
        g.func.delay(nil, 5)
      end)
    end)

    it("should error when delay is not a number", function()
      assert.has_error(function()
        g.func.delay(function() end, "soon")
      end)
    end)

    it("should error when delay is nil", function()
      assert.has_error(function()
        g.func.delay(function() end)
      end)
    end)
  end)

  describe("repeater", function()
    it("should call the function immediately once", function()
      local count = 0
      g.func.repeater(function() count = count + 1 end, 1, 3)
      assert.are.equal(1, count)
    end)

    it("should schedule the next tick with the given interval", function()
      g.func.repeater(function() end, 4, 3)
      assert.are.equal(4, timer_callbacks[1].delay)
    end)

    it("should call the function once per tick up to times", function()
      local count = 0
      g.func.repeater(function() count = count + 1 end, 1, 3)
      -- first call already happened synchronously; drive the remaining ticks
      fire_timer(1)
      fire_timer(2)
      fire_timer(3)
      assert.are.equal(3, count)
    end)

    it("should stop after reaching times", function()
      local count = 0
      g.func.repeater(function() count = count + 1 end, 1, 2)
      fire_timer(1)
      fire_timer(2)
      fire_timer(3)
      assert.are.equal(2, count)
    end)

    it("should forward varargs on the first call", function()
      local received
      g.func.repeater(function(...) received = {...} end, 1, 2, "a", "b")
      assert.are.same({"a", "b"}, received)
    end)

    it("should forward varargs after the first tick", function()
      local calls = {}
      g.func.repeater(function(...) calls[#calls + 1] = {...} end, 1, 3, "x", "y")
      fire_timer(1)
      fire_timer(2)
      assert.are.same({"x", "y"}, calls[2])
      assert.are.same({"x", "y"}, calls[3])
    end)

    it("should default interval and times to 1 when omitted", function()
      local count = 0
      g.func.repeater(function() count = count + 1 end)
      assert.are.equal(1, count)
      assert.are.equal(1, timer_callbacks[1].delay)
    end)

    it("should not call the function when times is 0", function()
      local count = 0
      g.func.repeater(function() count = count + 1 end, 1, 0)
      assert.are.equal(0, count)
    end)

    it("should error when func is not a function", function()
      assert.has_error(function()
        g.func.repeater("nope", 1, 1)
      end)
    end)

    it("should error when interval is not a number", function()
      assert.has_error(function()
        g.func.repeater(function() end, "fast", 1)
      end)
    end)

    it("should error when times is not a number", function()
      assert.has_error(function()
        g.func.repeater(function() end, 1, "lots")
      end)
    end)
  end)

  describe("wrap", function()
    it("should return a function", function()
      local wrapped = g.func.wrap(function() end, function() end)
      assert.are.equal("function", type(wrapped))
    end)

    it("should call the wrapper with the wrapped function first", function()
      local received
      local target = function() end
      local wrapped = g.func.wrap(target, function(f) received = f end)
      wrapped()
      assert.are.equal(target, received)
    end)

    it("should forward arguments to the wrapper", function()
      local received
      local wrapped = g.func.wrap(function() end, function(f, ...) received = {...} end)
      wrapped("a", "b")
      assert.are.same({"a", "b"}, received)
    end)

    it("should return the wrapper's return value", function()
      local wrapped = g.func.wrap(function() end, function(f, x) return x * 2 end)
      assert.are.equal(10, wrapped(5))
    end)

    it("should let the wrapper invoke the wrapped function", function()
      local inner_called = false
      local target = function() inner_called = true end
      local wrapped = g.func.wrap(target, function(f) f() end)
      wrapped()
      assert.is_true(inner_called)
    end)

    it("should error when func is not a function", function()
      assert.has_error(function()
        g.func.wrap("nope", function() end)
      end)
    end)

    it("should error when wrapper is not a function", function()
      assert.has_error(function()
        g.func.wrap(function() end, "nope")
      end)
    end)
  end)
end)
