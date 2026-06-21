-- Glu cannot use Glass because the constructors will be different. The
-- factory is for modules and any other classes in Glu.

if not _G["Glu"] then
  Glu = {}
  Glu.__index = Glu
  table.unpack = table.unpack or unpack

  local registeredGlasses = {}

  local function unregisterGlass(name)
    for i, glass in ipairs(registeredGlasses) do
      if glass.name == name then
        table.remove(registeredGlasses, i)
        return
      end
    end
  end

  function Glu.get_glasses() return registeredGlasses end

  function Glu.get_glass_names()
    local names = {}
    local glasses = Glu.get_glasses()
    for _, glass in ipairs(glasses or {}) do
      table.insert(names, glass.name)
    end
    return names
  end

  function Glu.get_glass(name)
    for _, glass in ipairs(Glu.get_glasses()) do
      if glass.name == name then
        return glass
      end
    end
    return nil
  end

  function Glu.has_glass(name)
    return Glu.get_glass(name) ~= nil
  end

  function Glu.id()
    local function random_hex(length)
      return string.format("%0" .. length .. "x", math.random(0, 16 ^ length - 1))
    end

    local result = string.format("%s%s-%s-4%s-%x%s-%s%s%s",
      random_hex(4),
      random_hex(4),
      random_hex(4),
      random_hex(3),
      8 + math.random(0, 3),
      random_hex(3),
      random_hex(4),
      random_hex(4),
      random_hex(4)
    )

    ---@diagnostic disable-next-line: return-type-mismatch
    return result
  end

  -- Make Glu callable
  setmetatable(Glu, { __call = function(_, ...) return Glu.new(...) end })

  local function new_object(glu_instance, glass, instance_opts, container)
    instance_opts = instance_opts or {}
    container = container or glu_instance

    -- Check for circular dependencies
    local function check_index_for_loop(ob)
      local seen = {}
      local current = ob

      while current do
        if seen[current] then
          error(">>   [newObject] Loop detected in __index chain for: " .. ob.name)
        end
        seen[current] = true
        current = getmetatable(current) and getmetatable(current).__index
      end
      return false
    end

    local function copy_properties(glu_class, into)
      local object = into[glu_class.name]
      for k, v in pairs(object) do
        glu_instance[glu_class.name][k] = v
      end

      -- Copy metatable info
      local meta = getmetatable(object)
      if meta then
        setmetatable(glu_instance[glu_class.name], meta)
      end
    end

    local function instantiate(glu, glu_class, ops, into)
      if check_index_for_loop(glu_class) then return end
      -- If the class has a parent, make sure it is instantiated first
      if glu_class.extends then
        local parent_name = glu_class.extends
        local parent = into.get_object(parent_name)

        if not parent then
          local parent_class = Glu.get_glass(parent_name)
          if not parent_class then
            error("Parent class `" .. parent_name .. "` not found for `" .. glu_class.name .. "`")
          end
          -- Recursively instantiate the parent class
          instantiate(glu, parent_class, ops, into)
        end
      end

      -- Instantiate the current class if it hasn't been already
      if not glu[glu_class.name] or table.index_of(table.keys(glu[glu_class.name]), "name") == nil then
        local object = glu_class(ops, glu)
        into[glu_class.name] = object -- Add the instance to `instance`
        copy_properties(glu_class, into)
        return object
      end
    end
    return instantiate(glu_instance, glass, instance_opts, container)
  end

  function Glu.new(pkg, module_dir_name)
    assert(type(pkg) == "string", "Package name must be a string.")
    assert(type(module_dir_name) == "string" or module_dir_name == nil, "Module directory name must be a string or nil.")

    -- For single-file distributions, module_dir_name can be nil and glasses
    -- are already registered when the file is loaded

    local instance = {
      name = "Glu",
      package_name = pkg,
      module_dir_name = module_dir_name,
      objects = {},
      container = nil,
      TYPE = {
        BOOLEAN = "boolean",
        ["boolean"] = "boolean",
        FUNCTION = "function",
        ["function"] = "function",
        NIL = "nil",
        ["nil"] = "nil",
        NUMBER = "number",
        ["number"] = "number",
        STRING = "string",
        ["string"] = "string",
        TABLE = "table",
        ["table"] = "table",
        THREAD = "thread",
        ["thread"] = "thread",
        USERDATA = "userdata",
        ["userdata"] = "userdata",
      },
      ENUM_ELEMENT_TYPE = { INDEXED = 1, MIXED = 2 }
    }

    -- Add the Glass class to the instance
    instance.glass = Glu.glass
    -- Add the Void class to the instance
    instance.void = Glu.void

    setmetatable(instance, Glu)

    -- If registeredGlasses is empty, it means that we weren't loaded
    -- from a package with Mudlet. So, we have to detect the glasses ourselves.
    -- This only applies when we have a module_dir_name (multi-file distribution).
    -- In single-file distributions, glasses are already registered.
    if table.size(registeredGlasses) == 0 then
      if not module_dir_name then
        error("No glasses registered and no module_dir_name provided. " ..
          "For single-file distributions, ensure all Glass classes are registered before calling Glu.new(). " ..
          "For multi-file distributions, provide module_dir_name parameter.")
      end

      -- In the event that we have added Glu in our package as resource files,
      -- we need to detect those glasses and load them.
      local function detectGlasses(module_path, require_path)
        local filter = "glu.lua"

        for file in lfs.dir(module_path) do
          if file:match("%.lua$") and file ~= filter then
            local module_name = file:match("^(.-)%.lua$")
            local require_file = string.format("%s/%s", require_path, module_name)
            assert(type(module_name) == "string", "Module name must be a string")
            assert(type(require_file) == "string", "Module file must be a string")
            require(require_file) -- load the file. its event handler will fire
          end
        end
      end

      local pkg_path = getMudletHomeDir() .. "/" .. pkg
      local module_path = pkg_path .. "/" .. module_dir_name
      local require_path = pkg .. "/" .. module_dir_name

      assert(lfs.attributes(pkg_path), "Package directory " .. pkg .. " does not exist")
      assert(lfs.attributes(module_path), "Module directory " .. module_dir_name .. " does not exist in package " .. pkg)

      detectGlasses(module_path, require_path)
    end

    -- Either way, we should have glasses by now.
    assert(table.size(registeredGlasses) > 0, "No glasses found in " .. pkg)

    function instance.getPackageName() return instance.package_name end

    function instance.has_object(name) return instance.get_object(name) ~= nil end

    function instance.get_object(name)
      return instance[name] and type(instance[name]) == "table" and instance[name] or
          nil
    end

    -- OOB Validation functions
    -- Standard validation functions
    local trace_ignore = debug.getinfo(1).source
    function instance.get_last_traceback_line()
      local it, trace = 1, ""
      while debug.getinfo(it) do
        if debug.getinfo(it).source ~= trace_ignore then
          local line = debug.getinfo(it).source ..
              ":" ..
              debug.getinfo(it).currentline
          trace = trace .. line .. "\n"
        end
        it = it + 1
      end

      if #trace == 0 then
        return "[No traceback]"
      end

      return trace
    end

    instance.v = {
      get_last_traceback_line = instance.get_last_traceback_line,
      test = function(statement, value, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = instance.get_last_traceback_line()
        assert(statement, "Invalid value to argument " .. argument_index ..
          ". " .. tostring(value) .. " in\n" .. last)
      end,
      type = function(value, expected_type, argument_index, nil_allowed)
        local last = instance.get_last_traceback_line()
        assert((nil_allowed == true and value == nil) or value ~= nil,
          "value must not be nil for argument " .. argument_index ..
          " in\n" .. last)
        assert(type(expected_type) == "string",
          "expected_type must be a string for argument " .. argument_index ..
          " in\n" .. last)
        assert(type(argument_index) == "number",
          "argument_index must be a number for argument " .. argument_index ..
          " in\n" .. last)
        assert(nil == nil_allowed or type(nil_allowed) == "boolean",
          "nil_allowed must be a boolean for argument " .. argument_index ..
          " in\n" .. last)

        if nil_allowed and value == nil then return end
        if expected_type == "any" then return end

        local expected_types = string.split(expected_type, "|") or { expected_type }
        local invalid = table.n_filter(expected_types, function(t) return not instance.TYPE[t] end)

        if table.size(invalid) > 0 then
          error("Invalid type to argument " ..
            argument_index .. ". Expected " .. table.concat(invalid, "|") .. ", got " .. type(value) .. " in\n" .. last)
        end

        for _, t in ipairs(expected_types) do
          if type(value) == t then return end
        end

        error("Invalid type to argument " ..
          argument_index .. ". Expected " .. expected_type .. ", got " .. type(value) .. " in\n" .. last)
      end,
      not_nil = function(value, argument_index)
        local last = instance.get_last_traceback_line()
        assert(value ~= nil, "value must not be nil for argument " .. argument_index .. " in\n" .. last)
      end,
      same_type = function(value1, value2, argument_index1, argument_index2)
        argument_index1 = argument_index1 or 1
        argument_index2 = argument_index2 or 2
        local last = instance.get_last_traceback_line()
        assert(type(value1) == type(value2),
          "Type mismatch: argument " .. argument_index1 .. " is " ..
          type(value1) .. " but argument " .. argument_index2 .. " is " ..
          type(value2) .. " in\n" .. last)
      end
    }

    -- Let's now create them!
    for _, class in ipairs(registeredGlasses) do
      new_object(instance, class, {}, instance)
    end

    --- Register a glass on this instance after construction.
    --- Delegates to Glu.glass.register and then instantiates the
    --- glass on this instance so it is immediately available.
    ---@param class_opts table Glass registration options (same as Glu.glass.register)
    ---@return table glass The registered glass class
    function instance.register(class_opts)
      local is_new = not Glu.has_glass(class_opts.name)
      local glass = Glu.glass.register(class_opts)
      local ok, err = pcall(new_object, instance, glass, {}, instance)
      if not ok then
        if is_new then
          unregisterGlass(class_opts.name)
        end
        error(err)
      end
      return glass
    end

    -- Trap events for uninstalling the package and clean ourselves up.
    local handler_name = "glu_sysUninstall_" .. Glu.id()
    instance.handler_name = handler_name
    registerNamedEventHandler("glu", handler_name, "sysUninstall",
      function(event, p)
        if p == instance.package_name then
          deleteNamedEventHandler("glu", handler_name)
          instance = nil
        end
      end
    )

    return instance
  end

  -- Glass
  Glass = {
    name = "glu_glass",
    class_name = "Glass",
    extends = nil,
    dependencies = {},
    protect = function(glass, self)
      local function protect_function(object, function_name)
        assert(type(object) == "table", "`object` must be a table")
        assert(type(function_name) == "string", "`function_name` must be a string")

        local original_function = object[function_name]
        assert(type(original_function) == "function", "`original_function` must be a function")

        object[function_name] = function(caller, ...)
          if self.extending(object) then
            return original_function(caller, ...)
          end
          error("Access denied: " .. function_name .. " is protected and can " ..
            "only be called by extending classes.")
        end
      end

      local function protect_variable(object, var_name)
        assert(type(object) == "table", "`object` must be a table")
        assert(type(var_name) == "string", "`var_name` must be a string")
        assert(type(object[var_name]) ~= "nil", "`object[var_name]` must not be nil")

        local base_class = getmetatable(object)

        setmetatable(object, {
          __index = function(tbl, key)
            if key == var_name and not self.extending(tbl, base_class) then
              error("Access denied: Variable '" ..
                var_name .. "' is protected and can only be accessed by extending classes.")
            end
            return rawget(tbl, key)
          end,
          __newindex = function(tbl, key, value)
            if key == var_name and not self.extending(tbl, base_class) then
              error("Access denied: Variable '" ..
                var_name .. "' is protected and can only be modified by extending classes.")
            end
            rawset(tbl, key, value)
          end,
        })
      end

      if glass.protected_functions then
        for _, function_name in ipairs(glass.protected_functions) do
          protect_function(self, function_name)
        end
      end

      if glass.protected_variables then
        for _, var_name in ipairs(glass.protected_variables) do
          protect_variable(self, var_name)
        end
      end
    end,
    register = function(class_opts)
      assert(type(class_opts) == "table", "opts must be a table")
      assert(type(class_opts.name) == "string", "`name` must be a string")
      assert(type(class_opts.class_name) == "string", "`class_name` must " ..
        "be a string")
      assert(type(class_opts.extends) == "string" or
        class_opts.extends == nil,
        "`extends` must be a string or nil")
      assert(type(class_opts.setup) == "function", "`setup` must " ..
        "be a function")
      assert(type(class_opts.valid) == "function" or class_opts.valid == nil,
        "`valid` must be a function or nil")

      -- After the other assertions
      if class_opts.adopts then
        assert(type(class_opts.adopts) == "table", "`adopts` must be a table")

        for class_name, adoption in pairs(class_opts.adopts) do
          assert(type(class_name) == "string", "adoption class name must be a string")
          assert(type(adoption) == "table", "adoption configuration must be a table")
          assert(type(adoption.methods) == "table", "adoption methods must be a table")

          -- Verify all method names are strings
          for _, method in ipairs(adoption.methods) do
            assert(type(method) == "string", "adopted method names must be strings")
          end
        end
      end

      local name = class_opts.name

      -- Declare the class. And return it if it already exists.
      local G = Glu.get_glass(name)
      if G then return G end

      G = {
        name = name,
        class_name = class_opts.class_name,
        extends = class_opts.extends,
        adopts = class_opts.adopts,
        dependencies = class_opts.dependencies or {},
        setup = class_opts.setup,
        valid = class_opts.valid,
        protected_functions = class_opts.protected_functions,
        protected_variables = class_opts.protected_variables,
      }

      function G.new(instance_opts, container)
        -- The instance_opts must be a table or nil
        assert(type(instance_opts) == "table" or instance_opts == nil,
          "`instance_opts` must be a table or nil")

        -- The container must be a table with a metatable, otherwise we
        -- we move it to the void.
        assert(container == nil or type(container) == "table",
          "`container` must be a table or nil")

        -- Setup instance
        local self = {
          extends = class_opts.extends,
          name = class_opts.name,
          class = class_opts.class_name,
          call = class_opts.call,
          objects = {},
          object = true,
        }
        self.__index = self

        container = container or self.get_void()
        assert(getmetatable(container) ~= nil, "`container` must have a metatable")

        self.container = container
        -- Determine anchor
        local ___ = self
        repeat ___ = ___.container until not ___.container

        self.___ = ___

        -- Set the __index for extension if this class extends another
        if class_opts.extends then
          local extends_class = class_opts.extends
          local parent_instance = ___.get_object(extends_class)

          if not parent_instance then
            error("Instance of parent class `" .. extends_class .. "` not " ..
              "found for `" .. class_opts.class_name .. "`")
          end

          self.parent = parent_instance

          setmetatable(self, { __index = parent_instance })
        else
          self.__index = self
          setmetatable(self, {})
        end

        -- Handle adoptions
        if class_opts.adopts then
          local mt = getmetatable(self)
          local adopted_methods = {}

          for class_name, adoption in pairs(class_opts.adopts) do
            -- printError("", true)
            local master_object = ___.get_object(class_name)
            if not master_object then
              error("Cannot adopt from class `" .. class_name .. "`: class not found")
            end
            -- display(master_object)
            -- Add each method from the donor class
            for _, method_name in ipairs(adoption.methods) do
              if type(master_object[method_name]) ~= "function" then
                error("Cannot adopt method `" .. method_name .. "` from `" ..
                  class_name .. "`: method not found")
              end
              adopted_methods[method_name] = master_object[method_name]
            end
          end

          -- If we're extending, merge with parent's __index
          local mt = getmetatable(self) or {}
          if type(mt.__index) == "table" then
            for k, v in pairs(adopted_methods) do
              mt.__index[k] = v
            end
          else
            -- Not extending, just set the adopted methods
            mt.__index = adopted_methods
          end
        end

        for _, dep in ipairs(class_opts.dependencies or {}) do
          local obj = ___[dep]
          if not obj then
            local glass = Glu.get_glass(dep)
            if not glass then
              error("Object `" .. dep .. "` not found for `" ..
                class_opts.class_name .. "`")
            else
              obj = new_object(___, glass, {}, ___.container)
            end
          end
        end

        -- If we don't have a name, use a random UUID
        local instance_name = self.name or ___.id()

        -- Validation functions
        if G.valid and type(G.valid) == "function" then
          ___.v = ___.v or {}
          local valid = G.valid(___, self)
          if valid then
            for valid_function_name, valid_function in pairs(valid) do
              ___.v[valid_function_name] = valid_function
            end
          end
        end

        -- Add the instance to the container
        container.objects[instance_name] = self
        if table.index_of(table.keys(G), "setup") and
            type(G.setup) == "function" then
          -- Initialize the instance
          G.setup(___, self, instance_opts, container)
        end

        --- Determines whether this instance extends the given base class.
        --- Walks up the parent chain looking for a match against the base class.
        ---
        ---@param base_class table The base class to check against.
        ---@return boolean extends Whether this instance extends the base class.
        function self.extending(base_class)
          local current_instance = self
          while current_instance do
            if current_instance == base_class then
              return true
            end
            current_instance = current_instance.parent
          end
          return false
        end

        -- Protect the functions and variables
        ___.glass.protect(G, self)

        assert(type(self.call) == "string" or self.call == nil,
          "`call` must be a string or nil")

        if self.call then
          local mt = getmetatable(self) or {}
          mt.__call = function(_, ...)
            local args = { ... }
            return self[self.call](unpack(args))
          end
          setmetatable(self, mt)
        end

        return self
      end

      table.insert(registeredGlasses, G)

      -- Set the metatable for the class. Always use the class's own `new` method for `__call`.
      setmetatable(G, {
        __index = class_opts.extends or nil,
        __call = function(_, ...) return G.new(...) end
      })

      tempTimer(0, function() raiseEvent("Glu.Glass.Registered", G) end)

      return G
    end
  }
  setmetatable(Glass, {
    __index = Glass,
    __call = function(_, ...) return Glass.new(...) end
  })
  Glu.glass = Glass

  -- We need a void class to hold objects that don't have a container.
  local Void = {
    name = "void",
    class_name = "VoidClass",
    objects = {},
  }
  Void.__index = Void
  Glu.void = Void
end
