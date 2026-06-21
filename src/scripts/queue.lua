local QueueClass = Glu.glass.register({
  name = "queue",
  class_name = "QueueClass",
  call = "new_queue",
  dependencies = { "table" },
  setup = function(___, self)
    self.queues = {}

    --- Instantiates a new queue stack object and adds it to the list of
    --- queues. The object will contain a property that is the ID may be used
    --- to manipulate the queue. The same functionality to manipulate the queue
    ---
    --- is available both through the queue object and the functions from this
    --- module. The ID is in the form of a v4 UUID.
    ---
    ---@param funcs table? A table of functions to be added to the queue
    ---@return table queue The new queue object
    ---
    ---@example
    --- ```lua
    --- local queue = queue.new(parent).new({})
    --- ```
    function self.new_queue(funcs)
      ___.v.type(funcs, "table", 1, true)
      ___.v.n_uniform(funcs, "function", 1, true)

      funcs = funcs or {}
      local queue = Glu.get_glass("queue_stack").new({ funcs = funcs }, self)
      ___.table.push(self.queues, queue)

      return queue
    end

    --- Retrieves a queue object by its identifier. If no queue is found, nil is
    --- returned, otherwise the queue object is returned.
    ---
    ---@param id string The identifier of the queue to retrieve
    ---@return table|nil queue The queue object or nil if not found
    function self.get(id)
      ___.v.type(id, "string", 1, false)

      for _, q in pairs(self.queues) do
        if q.id == id then return q end
      end
      return nil, f "Queue not found for id `{id}`."
    end

    --- Add a function to the end of a queue by its identifier.
    ---
    ---@param id string The identifier of the queue to add the function to
    ---@param f function The function to add to the queue
    ---@example
    --- ```lua
    --- queue:push("2ce02d6a-36a8-45ab-a78e-7f909427e1d1",
    ---   function() print("Hello, world!")
    --- end)
    --- ```
    function self.push(id, f)
      ___.v.type(id, "string", 1, false)
      ___.v.type(f, "function", 2, false)

      local q, err = self.get(id)
      if not q then return nil, err end

      return q.push(f)
    end

    --- Removes and returns the next item from the named queue.
    ---
    ---@param id string The identifier of the queue to shift from.
    ---@return any item The next item removed from the queue, or nil on failure.
    ---@return string err An error message if the queue could not be found.
    function self.shift(id)
      ___.v.type(id, "string", 1, false)

      local q, err = self.get(id)
      if not q then return nil, err end

      return q.shift()
    end
  end
})
