describe("glu core framework", function()
  local g

  setup(function()
    g = Glu("Glu")
  end)

  -- ========================================================================
  -- Glu.new
  -- ========================================================================

  describe("Glu.new", function()
    it("should create an instance with package name", function()
      assert.is_truthy(g)
      assert.are.equal("Glu", g.package_name)
    end)

    it("should set the name to Glu", function()
      assert.are.equal("Glu", g.name)
    end)

    it("should be callable via Glu()", function()
      local g2 = Glu("Glu")
      assert.is_truthy(g2)
      assert.are.equal("Glu", g2.package_name)
    end)

    it("should error on non-string package name", function()
      assert.has_error(function()
        Glu.new(123)
      end)
    end)

    it("should error on non-string module_dir_name", function()
      assert.has_error(function()
        Glu.new("Glu", 123)
      end)
    end)

    it("should have TYPE constants", function()
      assert.are.equal("string", g.TYPE.STRING)
      assert.are.equal("number", g.TYPE.NUMBER)
      assert.are.equal("boolean", g.TYPE.BOOLEAN)
      assert.are.equal("table", g.TYPE.TABLE)
      assert.are.equal("function", g.TYPE.FUNCTION)
      assert.are.equal("nil", g.TYPE.NIL)
    end)

    it("should have TYPE constants in lowercase too", function()
      assert.are.equal("string", g.TYPE["string"])
      assert.are.equal("number", g.TYPE["number"])
      assert.are.equal("boolean", g.TYPE["boolean"])
    end)
  end)

  -- ========================================================================
  -- Glu.id
  -- ========================================================================

  describe("Glu.id", function()
    it("should return a string", function()
      assert.are.equal("string", type(Glu.id()))
    end)

    it("should return a UUID v4 format", function()
      local id = Glu.id()
      -- UUID v4: xxxxxxxx-xxxx-4xxx-[89ab]xxx-xxxxxxxxxxxx
      assert.is_truthy(rex.match(id, "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"))
    end)

    it("should generate unique ids", function()
      local id1 = Glu.id()
      local id2 = Glu.id()
      assert.are_not.equal(id1, id2)
    end)

    it("should always have 4 as version digit", function()
      local id = Glu.id()
      local parts = id:split("-")
      assert.are.equal("4", parts[3]:sub(1, 1))
    end)
  end)

  -- ========================================================================
  -- Glu.get_glass / has_glass / get_glass_names
  -- ========================================================================

  describe("glass registry", function()
    it("should find a registered glass by name", function()
      local glass = Glu.get_glass("table")
      assert.is_truthy(glass)
      assert.are.equal("table", glass.name)
    end)

    it("should return nil for unregistered glass", function()
      assert.is_nil(Glu.get_glass("nonexistent_glass"))
    end)

    it("should report has_glass correctly for existing", function()
      assert.is_true(Glu.has_glass("table"))
      assert.is_true(Glu.has_glass("string"))
      assert.is_true(Glu.has_glass("number"))
    end)

    it("should report has_glass correctly for non-existing", function()
      assert.is_false(Glu.has_glass("nonexistent_glass"))
    end)

    it("should return list of registered glass names", function()
      local names = Glu.get_glass_names()
      assert.is_truthy(names)
      assert.is_true(#names > 0)
      assert.is_truthy(table.index_of(names, "table"))
      assert.is_truthy(table.index_of(names, "string"))
      assert.is_truthy(table.index_of(names, "number"))
    end)

    it("should return all glasses", function()
      local glasses = Glu.get_glasses()
      assert.is_truthy(glasses)
      assert.is_true(#glasses > 0)
    end)
  end)

  -- ========================================================================
  -- Instance module access
  -- ========================================================================

  describe("module access", function()
    it("should have table module", function()
      assert.is_truthy(g.table)
    end)

    it("should have string module", function()
      assert.is_truthy(g.string)
    end)

    it("should have number module", function()
      assert.is_truthy(g.number)
    end)

    it("should have colour module", function()
      assert.is_truthy(g.colour)
    end)

    it("should have fd module", function()
      assert.is_truthy(g.fd)
    end)

    it("should have http module", function()
      assert.is_truthy(g.http)
    end)
  end)

  -- ========================================================================
  -- has_object / get_object
  -- ========================================================================

  describe("has_object / get_object", function()
    it("should find existing module objects", function()
      assert.is_true(g.has_object("table"))
      assert.is_true(g.has_object("string"))
    end)

    it("should return false for non-existing objects", function()
      assert.is_false(g.has_object("nonexistent"))
    end)

    it("should return the object for existing", function()
      local obj = g.get_object("table")
      assert.is_truthy(obj)
    end)

    it("should return nil for non-existing objects", function()
      assert.is_nil(g.get_object("nonexistent"))
    end)
  end)

  -- ========================================================================
  -- getPackageName
  -- ========================================================================

  describe("getPackageName", function()
    it("should return the package name", function()
      assert.are.equal("Glu", g.getPackageName())
    end)
  end)

  -- ========================================================================
  -- Validators (v.type, v.test, v.not_nil, v.same_type)
  -- ========================================================================

  describe("validators", function()
    describe("v.type", function()
      it("should pass for correct type", function()
        assert.has_no.errors(function()
          g.v.type("hello", "string", 1, false)
        end)
      end)

      it("should error for wrong type", function()
        assert.has_error(function()
          g.v.type(123, "string", 1, false)
        end)
      end)

      it("should allow nil when nil_allowed is true", function()
        assert.has_no.errors(function()
          g.v.type(nil, "string", 1, true)
        end)
      end)

      it("should error on nil when nil_allowed is false", function()
        assert.has_error(function()
          g.v.type(nil, "string", 1, false)
        end)
      end)

      it("should accept any type", function()
        assert.has_no.errors(function()
          g.v.type("hello", "any", 1, false)
          g.v.type(123, "any", 1, false)
          g.v.type({}, "any", 1, false)
        end)
      end)

      it("should accept union types", function()
        assert.has_no.errors(function()
          g.v.type("hello", "string|number", 1, false)
          g.v.type(123, "string|number", 1, false)
        end)
      end)

      it("should error on union type mismatch", function()
        assert.has_error(function()
          g.v.type(true, "string|number", 1, false)
        end)
      end)
    end)

    describe("v.test", function()
      it("should pass when statement is true", function()
        assert.has_no.errors(function()
          g.v.test(true, "value", 1, false)
        end)
      end)

      it("should error when statement is false", function()
        assert.has_error(function()
          g.v.test(false, "value", 1, false)
        end)
      end)

      it("should allow nil value when nil_allowed", function()
        assert.has_no.errors(function()
          g.v.test(true, nil, 1, true)
        end)
      end)
    end)

    describe("v.not_nil", function()
      it("should pass for non-nil value", function()
        assert.has_no.errors(function()
          g.v.not_nil("hello", 1)
        end)
      end)

      it("should error for nil value", function()
        assert.has_error(function()
          g.v.not_nil(nil, 1)
        end)
      end)
    end)

    describe("v.same_type", function()
      it("should pass when both are same type", function()
        assert.has_no.errors(function()
          g.v.same_type("a", "b")
        end)
      end)

      it("should error when types differ", function()
        assert.has_error(function()
          g.v.same_type("a", 1)
        end)
      end)

      it("should default argument indices to 1 and 2", function()
        assert.has_no.errors(function()
          g.v.same_type(1, 2)
        end)
      end)

      it("should accept custom argument indices", function()
        assert.has_no.errors(function()
          g.v.same_type(1, 2, 3, 4)
        end)
      end)
    end)
  end)

  -- ========================================================================
  -- Glass.register
  -- ========================================================================

  describe("Glass.register", function()
    it("should return existing glass if already registered", function()
      local glass1 = Glu.get_glass("table")
      local glass2 = Glu.glass.register({
        name = "table",
        class_name = "TableClass",
        setup = function() end
      })
      assert.are.equal(glass1, glass2)
    end)

    it("should error on missing name", function()
      assert.has_error(function()
        Glu.glass.register({
          class_name = "TestClass",
          setup = function() end
        })
      end)
    end)

    it("should error on missing class_name", function()
      assert.has_error(function()
        Glu.glass.register({
          name = "test_glass_no_class",
          setup = function() end
        })
      end)
    end)

    it("should error on missing setup", function()
      assert.has_error(function()
        Glu.glass.register({
          name = "test_glass_no_setup",
          class_name = "TestClass"
        })
      end)
    end)

    it("should error on non-table opts", function()
      assert.has_error(function()
        Glu.glass.register("not a table")
      end)
    end)
  end)

  -- ========================================================================
  -- Dependency injection
  -- ========================================================================

  describe("dependencies", function()
    it("should resolve module dependencies", function()
      -- colour depends on number
      assert.is_truthy(g.colour)
      assert.is_truthy(g.number)
    end)

    it("should have all modules accessible from instance", function()
      local names = Glu.get_glass_names()
      for _, name in ipairs(names) do
        -- Every registered glass should be accessible on the instance
        assert.is_truthy(g[name], "Module '" .. name .. "' not found on instance")
      end
    end)
  end)

  -- ========================================================================
  -- instance.register (post-construction registration)
  -- ========================================================================

  describe("instance.register", function()
    it("should have a register function on the instance", function()
      assert.are.equal("function", type(g.register))
    end)

    it("should register and instantiate a simple glass", function()
      g.register({
        name = "post_reg_simple",
        class_name = "PostRegSimpleClass",
        dependencies = {},
        setup = function(___, self)
          function self.greet(name)
            return "hello " .. name
          end
        end
      })

      assert.is_truthy(g.post_reg_simple)
      assert.are.equal("hello world", g.post_reg_simple.greet("world"))
    end)

    it("should return the registered glass class", function()
      local glass = g.register({
        name = "post_reg_returns",
        class_name = "PostRegReturnsClass",
        dependencies = {},
        setup = function(___, self) end
      })

      assert.is_truthy(glass)
      assert.are.equal("post_reg_returns", glass.name)
      assert.are.equal("PostRegReturnsClass", glass.class_name)
    end)

    it("should make the glass available via has_object", function()
      g.register({
        name = "post_reg_has_obj",
        class_name = "PostRegHasObjClass",
        dependencies = {},
        setup = function(___, self) end
      })

      assert.is_true(g.has_object("post_reg_has_obj"))
    end)

    it("should make the glass available via get_object", function()
      g.register({
        name = "post_reg_get_obj",
        class_name = "PostRegGetObjClass",
        dependencies = {},
        setup = function(___, self) end
      })

      local obj = g.get_object("post_reg_get_obj")
      assert.is_truthy(obj)
    end)

    it("should also register in the global glass registry", function()
      g.register({
        name = "post_reg_global",
        class_name = "PostRegGlobalClass",
        dependencies = {},
        setup = function(___, self) end
      })

      assert.is_true(Glu.has_glass("post_reg_global"))
    end)

    it("should give the glass access to the glu instance via ___", function()
      g.register({
        name = "post_reg_glu_access",
        class_name = "PostRegGluAccessClass",
        dependencies = {},
        setup = function(___, self)
          function self.get_package_name()
            return ___.getPackageName()
          end
        end
      })

      assert.are.equal("Glu", g.post_reg_glu_access.get_package_name())
    end)

    it("should resolve dependencies on existing glasses", function()
      g.register({
        name = "post_reg_with_deps",
        class_name = "PostRegWithDepsClass",
        dependencies = { "table" },
        setup = function(___, self)
          function self.get_values(t)
            return ___.table.values(t)
          end
        end
      })

      local vals = g.post_reg_with_deps.get_values({ a = 1, b = 2 })
      assert.are.equal(2, #vals)
    end)

    it("should support callable glasses via call option", function()
      g.register({
        name = "post_reg_callable",
        class_name = "PostRegCallableClass",
        dependencies = {},
        call = "create",
        setup = function(___, self)
          function self.create(value)
            return { value = value, doubled = value * 2 }
          end
        end
      })

      local result = g.post_reg_callable(21)
      assert.are.equal(21, result.value)
      assert.are.equal(42, result.doubled)
    end)

    it("should not re-register an already registered glass", function()
      local first = g.register({
        name = "post_reg_idempotent",
        class_name = "PostRegIdempotentClass",
        dependencies = {},
        setup = function(___, self)
          self.marker = "first"
        end
      })

      local second = g.register({
        name = "post_reg_idempotent",
        class_name = "PostRegIdempotentClass",
        dependencies = {},
        setup = function(___, self)
          self.marker = "second"
        end
      })

      assert.are.equal(first, second)
    end)

    it("should error on missing name", function()
      assert.has_error(function()
        g.register({
          class_name = "NoNameClass",
          setup = function() end
        })
      end)
    end)

    it("should error on missing class_name", function()
      assert.has_error(function()
        g.register({
          name = "post_reg_no_class",
          setup = function() end
        })
      end)
    end)

    it("should error on missing setup", function()
      assert.has_error(function()
        g.register({
          name = "post_reg_no_setup",
          class_name = "NoSetupClass"
        })
      end)
    end)

    it("should error on non-table opts", function()
      assert.has_error(function()
        g.register("not a table")
      end)
    end)

    it("should support valid function for custom validators", function()
      g.register({
        name = "post_reg_valid",
        class_name = "PostRegValidClass",
        dependencies = {},
        setup = function(___, self) end,
        valid = function(___, self)
          return {
            is_positive = function(value, argument_index)
              assert(type(value) == "number" and value > 0,
                "value must be a positive number for argument " .. argument_index)
            end
          }
        end
      })

      assert.is_truthy(g.v.is_positive)
      assert.has_no.errors(function()
        g.v.is_positive(5, 1)
      end)
      assert.has_error(function()
        g.v.is_positive(-1, 1)
      end)
    end)
  end)

  -- ========================================================================
  -- instance.register edge cases
  -- ========================================================================

  describe("instance.register edge cases", function()
    it("should error when extending an unregistered parent", function()
      assert.has_error(function()
        g.register({
          name = "edge_orphan_child",
          class_name = "EdgeOrphanChildClass",
          extends = "edge_nonexistent_parent",
          dependencies = {},
          setup = function(___, self) end
        })
      end)
    end)

    it("should support extends when parent is registered post-construction", function()
      g.register({
        name = "edge_late_parent",
        class_name = "EdgeLateParentClass",
        dependencies = {},
        setup = function(___, self)
          function self.parent_method()
            return "from parent"
          end
        end
      })

      g.register({
        name = "edge_late_child",
        class_name = "EdgeLateChildClass",
        extends = "edge_late_parent",
        dependencies = {},
        setup = function(___, self)
          function self.child_method()
            return "from child"
          end
        end
      })

      assert.is_truthy(g.edge_late_child)
      assert.are.equal("from child", g.edge_late_child.child_method())
      assert.are.equal("from parent", g.edge_late_child.parent_method())
    end)

    it("should error when dependency does not exist", function()
      assert.has_error(function()
        g.register({
          name = "edge_bad_dep",
          class_name = "EdgeBadDepClass",
          dependencies = { "totally_nonexistent_module" },
          setup = function(___, self) end
        })
      end)
    end)

    it("should error when adopting from a non-existent class", function()
      assert.has_error(function()
        g.register({
          name = "edge_bad_adopt",
          class_name = "EdgeBadAdoptClass",
          dependencies = {},
          adopts = {
            nonexistent_class = {
              methods = { "some_method" }
            }
          },
          setup = function(___, self) end
        })
      end)
    end)

    it("should not clobber state when registering same glass twice", function()
      g.register({
        name = "edge_double_reg",
        class_name = "EdgeDoubleRegClass",
        dependencies = {},
        setup = function(___, self)
          self.counter = (self.counter or 0) + 1
          function self.get_counter()
            return self.counter
          end
        end
      })

      local first_counter = g.edge_double_reg.get_counter()

      -- Register again with same name - should be idempotent
      g.register({
        name = "edge_double_reg",
        class_name = "EdgeDoubleRegClass",
        dependencies = {},
        setup = function(___, self)
          self.counter = 999
        end
      })

      -- Counter should not have changed
      assert.are.equal(first_counter, g.edge_double_reg.get_counter())
    end)

    it("should make post-registered glass available to a new instance", function()
      -- Register on g first
      g.register({
        name = "edge_cross_instance",
        class_name = "EdgeCrossInstanceClass",
        dependencies = {},
        setup = function(___, self)
          function self.ping()
            return "pong"
          end
        end
      })

      -- New instance should have it since it's now in registeredGlasses
      local g2 = Glu("Glu")
      assert.is_truthy(g2.edge_cross_instance)
      assert.are.equal("pong", g2.edge_cross_instance.ping())
    end)

    it("should support a post-registered glass using another post-registered glass", function()
      g.register({
        name = "edge_provider",
        class_name = "EdgeProviderClass",
        dependencies = {},
        setup = function(___, self)
          function self.get_value()
            return 42
          end
        end
      })

      g.register({
        name = "edge_consumer",
        class_name = "EdgeConsumerClass",
        dependencies = { "edge_provider" },
        setup = function(___, self)
          function self.get_doubled()
            return ___.edge_provider.get_value() * 2
          end
        end
      })

      assert.are.equal(84, g.edge_consumer.get_doubled())
    end)

    it("should support callable glass that returns complex objects", function()
      g.register({
        name = "edge_factory",
        class_name = "EdgeFactoryClass",
        dependencies = {},
        call = "create",
        setup = function(___, self)
          function self.create(name, value)
            local obj = { name = name, value = value }
            function obj.describe()
              return obj.name .. "=" .. tostring(obj.value)
            end
            return obj
          end
        end
      })

      local thing = g.edge_factory("foo", 123)
      assert.are.equal("foo=123", thing.describe())

      -- Factory itself is still there
      local thing2 = g.edge_factory("bar", 456)
      assert.are.equal("bar=456", thing2.describe())
    end)

    it("should support extends on an already-instantiated built-in glass", function()
      g.register({
        name = "edge_extends_builtin",
        class_name = "EdgeExtendsBuiltinClass",
        extends = "queue",
        dependencies = {},
        setup = function(___, self)
          function self.custom_method()
            return "extended"
          end
        end
      })

      assert.is_truthy(g.edge_extends_builtin)
      assert.are.equal("extended", g.edge_extends_builtin.custom_method())
      -- Should have parent's methods via __index
      assert.is_truthy(g.edge_extends_builtin.push)
    end)

    it("should support adopts from an existing glass", function()
      g.register({
        name = "edge_adopter",
        class_name = "EdgeAdopterClass",
        dependencies = {},
        adopts = {
          string = {
            methods = { "trim" }
          }
        },
        setup = function(___, self) end
      })

      assert.is_truthy(g.edge_adopter)
      assert.is_truthy(g.edge_adopter.trim)
      assert.are.equal("hello", g.edge_adopter.trim("  hello  "))
    end)
  end)

  -- ========================================================================
  -- handler_name (uninstall event)
  -- ========================================================================

  describe("uninstall handler", function()
    it("should have a handler_name set", function()
      assert.is_truthy(g.handler_name)
      assert.are.equal("string", type(g.handler_name))
    end)

    it("should start with glu_sysUninstall_", function()
      assert.is_truthy(g.handler_name:find("^glu_sysUninstall_"))
    end)

    describe("when sysUninstall fires", function()
      local package_name = "__glu_test_uninstall__"
      local instance

      local function is_registered()
        return table.index_of(getNamedEventHandlers("glu"), instance.handler_name) ~= nil
      end

      before_each(function()
        instance = Glu(package_name)
      end)

      after_each(function()
        deleteNamedEventHandler("glu", instance.handler_name)
      end)

      it("should remove its handler when its own package is uninstalled", function()
        assert.is_true(is_registered())

        raiseEvent("sysUninstall", package_name)

        assert.is_false(is_registered())
      end)

      it("should keep its handler when another package is uninstalled", function()
        raiseEvent("sysUninstall", "__glu_test_some_other_package__")

        assert.is_true(is_registered())
      end)
    end)
  end)
end)
