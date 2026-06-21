local QueueStackClass = Glu.glass.register({
  name = "queue_stack",
  class_name = "QueueStackClass",
  dependencies = { "table" },
  setup = function(___, self, opts, container)
    local funcs = ___.table.n_cast(opts.funcs or {})
    ___.v.n_uniform(funcs, "function", 2, false)

    self.stack = funcs
    self.id = ___.id()

    --- Pushes a function onto the end of the queue.
    ---
    ---@param f function The task function to add to the queue.
    ---@returns number The new length of the queue.
    function self.push(f)
      ___.v.type(f, "function", 1, false)
      return ___.table.push(self.stack, f)
    end

    --- Removes and returns the first task from the front of the queue.
    ---
    ---@returns function|nil The shifted task function, or nil if the queue is empty.
    function self.shift()
      return ___.table.shift(self.stack)
    end

    --- Shifts the next task off the queue and executes it with the provided arguments.
    ---
    ---@param ... any The arguments to pass to the task function.
    ---@returns QueueStackClass The queue object.
    ---@returns number|nil The number of remaining tasks, or nil when the queue is empty.
    ---@returns any ... Any results returned by the executed task.
    function self.execute(...)
      -- Shift the next task off the queue
      local task = self.shift()
      if not task then
        return self, nil -- Queue is empty, return nil for remaining count
      end

      -- Execute the task with the provided arguments and store the result(s)
      local result = { task(self, ...) }

      -- Determine remaining task count, returning nil if no tasks remain
      local count = #self.stack
      return self, count > 0 and count or nil, unpack(result)
    end
  end
})
