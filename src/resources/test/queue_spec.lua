describe("queue module", function()
  local g

  setup(function()
    g = Glu("Glu")
  end)

  -- ========================================================================
  -- new_queue
  -- ========================================================================

  describe("new_queue", function()
    it("should create a queue and add it to queues list", function()
      local qs = g.queue.new_queue({})
      assert.is_truthy(qs)
      assert.are.equal(1, #g.queue.queues)
    end)

    it("should create multiple queues", function()
      g.queue.new_queue({})
      g.queue.new_queue({})
      assert.is_true(#g.queue.queues >= 2)
    end)

    it("should return a queue_stack with an id", function()
      local qs = g.queue.new_queue({})
      assert.are.equal("string", type(qs.id))
    end)

    it("should accept nil for empty queue", function()
      local qs = g.queue.new_queue()
      assert.is_truthy(qs)
    end)

    it("should error on non-function elements", function()
      assert.has_error(function()
        g.queue.new_queue({"not a function"})
      end)
    end)
  end)

  -- ========================================================================
  -- get
  -- ========================================================================

  describe("get", function()
    it("should retrieve a queue by id", function()
      local qs = g.queue.new_queue({})
      local found = g.queue.get(qs.id)
      assert.are.equal(qs, found)
    end)

    it("should return nil for unknown id", function()
      local found, err = g.queue.get("nonexistent-id")
      assert.is_nil(found)
      assert.is_truthy(err)
    end)

    it("should error on non-string id", function()
      assert.has_error(function()
        g.queue.get(123)
      end)
    end)

    it("should error on nil id", function()
      assert.has_error(function()
        g.queue.get(nil)
      end)
    end)
  end)

  -- ========================================================================
  -- push (by id)
  -- ========================================================================

  describe("delete", function()
    it("should remove a queue by id", function()
      local qs = g.queue.new_queue({})

      assert.is_true(g.queue.delete(qs.id))
      assert.is_nil(g.queue.get(qs.id))
    end)

    it("should leave other queues in place", function()
      local keep = g.queue.new_queue({})
      local remove = g.queue.new_queue({})

      g.queue.delete(remove.id)

      assert.are.equal(keep, g.queue.get(keep.id))
    end)

    it("should return nil and a message for unknown id", function()
      local removed, err = g.queue.delete("nonexistent-id")

      assert.is_nil(removed)
      assert.is_truthy(err)
    end)

    it("should error on non-string id", function()
      assert.has_error(function()
        g.queue.delete(123)
      end)
    end)
  end)

  describe("push", function()
    it("should add a function to a queue by id", function()
      local qs = g.queue.new_queue({})
      g.queue.push(qs.id, function() end)
      assert.are.equal(1, #qs.stack)
    end)

    it("should return new count", function()
      local qs = g.queue.new_queue({function() end})
      local count = g.queue.push(qs.id, function() end)
      assert.are.equal(2, count)
    end)

    it("should return nil for unknown id", function()
      local result, err = g.queue.push("nonexistent-id", function() end)
      assert.is_nil(result)
      assert.is_truthy(err)
    end)

    it("should error on non-string id", function()
      assert.has_error(function()
        g.queue.push(123, function() end)
      end)
    end)

    it("should error on non-function", function()
      assert.has_error(function()
        local qs = g.queue.new_queue({})
        g.queue.push(qs.id, "not a function")
      end)
    end)
  end)

  -- ========================================================================
  -- shift (by id)
  -- ========================================================================

  describe("shift", function()
    it("should remove and return the first function by id", function()
      local f = function() return "hello" end
      local qs = g.queue.new_queue({f})
      local shifted = g.queue.shift(qs.id)
      assert.are.equal(f, shifted)
    end)

    it("should return nil when queue is empty", function()
      local qs = g.queue.new_queue({})
      local shifted = g.queue.shift(qs.id)
      assert.is_nil(shifted)
    end)

    it("should return nil for unknown id", function()
      local result, err = g.queue.shift("nonexistent-id")
      assert.is_nil(result)
      assert.is_truthy(err)
    end)

    it("should error on non-string id", function()
      assert.has_error(function()
        g.queue.shift(123)
      end)
    end)
  end)
end)
