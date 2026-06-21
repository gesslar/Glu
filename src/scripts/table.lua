local TableClass = Glu.glass.register({
  name = "table",
  class_name = "TableClass",
  dependencies = {},
  setup = function(___, self)
    --- Casts the given value(s) into an indexed table. If a single indexed
    --- table is passed, it is returned unchanged; otherwise the arguments are
    --- collected into a new table.
    ---
    ---@param ... any The value(s) to cast into an indexed table.
    ---@return table result The resulting indexed table.
    ---@example
    --- ```lua
    --- table.n_cast(1, 2, 3)
    --- -- {1, 2, 3}
    --- ```
    function self.n_cast(...)
      if type(...) == "table" and self.indexed(...) then
        return ...
      end

      return { ... }
    end

    self.assure_indexed = self.n_cast

    --- Maps each element of a table to a new value using the provided function,
    --- preserving the original keys.
    ---
    ---@param t table The table to map over.
    ---@param fn function The function called as fn(key, value, ...) for each element.
    ---@param ... any Additional arguments passed to the mapping function.
    ---@return table result A new table with the mapped values.
    ---@example
    --- ```lua
    --- table.map({1, 2, 3}, function(k, v) return v * 2 end)
    --- -- {2, 4, 6}
    --- ```
    function self.map(t, fn, ...)
      ___.v.type(t, "table", 1, false)
      ___.v.type(fn, "function", 2, false)

      local result = {}
      for k, v in pairs(t) do
        result[k] = fn(k, v, ...)
      end
      return result
    end

    --- Returns an indexed table containing the values of the given table,
    --- discarding the keys.
    ---
    ---@param t table The table whose values to collect.
    ---@return table result An indexed table of the values.
    ---@example
    --- ```lua
    --- table.values({a = 1, b = 2})
    --- -- {1, 2}
    --- ```
    function self.values(t)
      ___.v.type(t, "table", 1, false)

      local result = {}
        for _, v in pairs(t) do
        result[#result + 1] = v
      end
      return result
    end

    --- Determines whether all elements of an indexed table are of the same
    --- type.
    ---
    ---@param t table The indexed table to check.
    ---@param typ string|nil The type to check against. (Optional. Default is the type of the first element.)
    ---@return boolean is_uniform True if all elements are of the given type, otherwise false.
    ---@example
    --- ```lua
    --- table.n_uniform({1, 2, 3})
    --- -- true
    --- ```
    function self.n_uniform(t, typ)
      ___.v.type(t, "table", 1, false)
      ___.v.indexed(t, 1, false)
      ___.v.type(typ, "string", 2, true)

      typ = typ or type(t[1])

      for _, v in pairs(t) do
        if type(v) ~= typ then
          return false
        end
      end

      return true
    end

    --- Returns a new indexed table containing only the distinct values of the
    --- given indexed table, preserving their first-seen order.
    ---
    ---@param t table The indexed table to deduplicate.
    ---@return table result A new indexed table of distinct values.
    ---@example
    --- ```lua
    --- table.n_distinct({1, 2, 2, 3, 3, 3})
    --- -- {1, 2, 3}
    --- ```
    function self.n_distinct(t)
      ___.v.indexed(t, 1, false)

      local result, seen = {}, {}
      for _, v in ipairs(t) do
        if not seen[v] then
          seen[v] = true
          result[#result + 1] = v
        end
      end
      return result
    end

    --- Removes and returns the last element of an indexed table.
    ---
    ---@param t table The indexed table to pop from.
    ---@return any removed The removed last element.
    ---@example
    --- ```lua
    --- table.pop({1, 2, 3})
    --- -- 3
    --- ```
    function self.pop(t)
      ___.v.type(t, "table", 1, false)
      ___.v.indexed(t, 1, false)
      return table.remove(t, #t)
    end

    --- Appends a value to the end of an indexed table.
    ---
    ---@param t table The indexed table to push onto.
    ---@param v any The value to append.
    ---@return number length The new length of the table.
    ---@example
    --- ```lua
    --- table.push({1, 2}, 3)
    --- -- 3
    --- ```
    function self.push(t, v)
      ___.v.type(t, "table", 1, false)
      ___.v.type(v, "any", 2, false)
      ___.v.indexed(t, 1, false)
      table.insert(t, v)

      return #t
    end

    --- Inserts a value at the beginning of an indexed table, shifting the
    --- existing elements up.
    ---
    ---@param t table The indexed table to unshift onto.
    ---@param v any The value to insert at the front.
    ---@return number length The new length of the table.
    ---@example
    --- ```lua
    --- table.unshift({2, 3}, 1)
    --- -- 3
    --- ```
    function self.unshift(t, v)
      ___.v.type(t, "table", 1, false)
      ___.v.type(v, "any", 2, false)
      ___.v.indexed(t, 1, false)
      table.insert(t, 1, v)

      return #t
    end

    --- Removes and returns the first element of an indexed table, shifting the
    --- remaining elements down.
    ---
    ---@param t table The indexed table to shift from.
    ---@return any removed The removed first element.
    ---@example
    --- ```lua
    --- table.shift({1, 2, 3})
    --- -- 1
    --- ```
    function self.shift(t)
      ___.v.type(t, "table", 1, false)
      ___.v.indexed(t, 1, false)
      return table.remove(t, 1)
    end

    --- Builds an associative table using the values of source as keys. The
    --- value for each key is taken from a parallel spec table, computed by a
    --- spec function, or set to a constant spec value.
    ---
    ---@param source table An indexed, non-empty table whose values become the keys.
    ---@param spec any A parallel indexed table, a function called as spec(index, key), or a constant value.
    ---@return table result The resulting associative table.
    ---@example
    --- ```lua
    --- table.allocate({"a", "b"}, {1, 2})
    --- -- {a = 1, b = 2}
    --- ```
    function self.allocate(source, spec)
      local spec_type = type(spec)
      ___.v.type(source, "table", 1, false)
      ___.v.not_empty(source, 1, false)
      ___.v.indexed(source, 1, false)
      if spec_type == ___.TYPE.TABLE then
        ___.v.indexed(spec, 2, false)
        assert(#source == #spec, "Expected source and spec to have the same number of elements")
      elseif spec_type == ___.TYPE.FUNCTION then
        ___.v.type(spec, "function", 2, false)
      end

      local result = {}

      if spec_type == ___.TYPE.TABLE then
        for i = 1, #spec do
          result[source[i]] = spec[i]
        end
      elseif spec_type == ___.TYPE.FUNCTION then
        for i = 1, #source do
          result[source[i]] = spec(i, source[i])
        end
      else
        for i = 1, #source do
          result[source[i]] = spec
        end
      end

      return result
    end

    --- Determines whether a table is indexed, meaning its keys are sequential
    --- integers starting at 1.
    ---
    ---@param t table The table to check.
    ---@return boolean is_indexed True if the table is indexed, otherwise false.
    ---@example
    --- ```lua
    --- table.indexed({1, 2, 3})
    --- -- true
    --- ```
    function self.indexed(t)
      ___.v.type(t, "table", 1, false)

      local index = 1
      for k in pairs(t) do
        if k ~= index then
          return false
        end
        index = index + 1
      end
      return true
    end

    --- Determines whether a table is associative, meaning it has at least one
    --- key that is not a positive integer.
    ---
    ---@param t table The table to check.
    ---@return boolean is_associative True if the table is associative, otherwise false.
    ---@example
    --- ```lua
    --- table.associative({a = 1})
    --- -- true
    --- ```
    function self.associative(t)
      ___.v.type(t, "table", 1, false)

      for k, _ in pairs(t) do
        if type(k) ~= "number" or k % 1 ~= 0 or k <= 0 then
            return true
        end
      end
      return false
    end

    --- Reduces a table to a single value by iteratively applying a function to
    --- an accumulator and each element.
    ---
    ---@param t table The indexed table to reduce.
    ---@param fn function The reducer called as fn(accumulator, value, key).
    ---@param initial any The initial value of the accumulator.
    ---@return any acc The final accumulated value.
    ---@example
    --- ```lua
    --- table.reduce({1, 2, 3}, function(acc, v) return acc + v end, 0)
    --- -- 6
    --- ```
    function self.reduce(t, fn, initial)
      ___.v.indexed(t, 1, false)
      ___.v.type(fn, "function", 2, false)
      ___.v.type(initial, "any", 3, false)

      local acc = initial
      for k, v in pairs(t) do
        acc = fn(acc, v, k)
      end
      return acc
    end

    --- Returns a new indexed table containing the elements from start to stop,
    --- inclusive.
    ---
    ---@param t table The indexed table to slice.
    ---@param start number The starting index (1-based).
    ---@param stop number|nil The ending index. (Optional. Default is the length of the table.)
    ---@return table result A new indexed table with the sliced elements.
    ---@example
    --- ```lua
    --- table.slice({1, 2, 3, 4}, 2, 3)
    --- -- {2, 3}
    --- ```
    function self.slice(t, start, stop)
      ___.v.indexed(t, 1, false)
      ___.v.type(start, "number", 2, false)
      ___.v.type(stop, "number", 3, true)
      ___.v.test(start >= 1, start, 2, false)
      ___.v.test(table.size(t) >= start, start, 2, false)
      ___.v.test(stop and stop >= start, stop, 3, true)

      if not stop then
        stop = #t
      end

      local result = {}
      for i = start, stop do
        result[#result + 1] = t[i]
      end
      return result
    end

    --- Removes a range of elements from an indexed table in place, returning the
    --- modified table and the removed elements.
    ---
    ---@param t table The indexed table to remove from.
    ---@param start number The starting index (1-based) of the range to remove.
    ---@param stop number|nil The ending index of the range. (Optional. Default is start.)
    ---@return table t The modified table with the range removed.
    ---@return table snipped An indexed table of the removed elements.
    ---@example
    --- ```lua
    --- table.remove({1, 2, 3, 4}, 2, 3)
    --- -- {1, 4}, {2, 3}
    --- ```
    function self.remove(t, start, stop)
      ___.v.indexed(t, 1, false)
      ___.v.type(start, "number", 2, false)
      ___.v.type(stop, "number", 3, true)
      ___.v.test(start >= 1, start, 2, false)
      ___.v.test(table.size(t) >= start, start, 2, false)
      ___.v.test(stop and stop >= start, stop, 3, true)

      local snipped = {}
      if not stop then stop = start end
      local count = stop - start + 1
      for i = 1, count do
        table.insert(snipped, table.remove(t, start))
      end
      return t, snipped
    end

    --- Splits an indexed table into a table of smaller indexed tables, each of
    --- the given size (the final chunk may be smaller).
    ---
    ---@param t table The indexed table to chunk.
    ---@param size number The maximum size of each chunk.
    ---@return table result A table of chunk tables.
    ---@example
    --- ```lua
    --- table.chunk({1, 2, 3, 4, 5}, 2)
    --- -- {{1, 2}, {3, 4}, {5}}
    --- ```
    function self.chunk(t, size)
      ___.v.indexed(t, 1, false)
      ___.v.type(size, "number", 2, false)

      local result = {}
      for i = 1, #t, size do
        result[#result + 1] = self.slice(t, i, math.min(i + size - 1, #t))
      end
      return result
    end

    --- Appends the given values to an indexed table in place. Table arguments
    --- are flattened one level, with their elements appended individually.
    ---
    ---@param tbl table The indexed table to append to.
    ---@param ... any The values or tables to append.
    ---@return table tbl The modified table.
    ---@example
    --- ```lua
    --- table.concat({1, 2}, {3, 4}, 5)
    --- -- {1, 2, 3, 4, 5}
    --- ```
    function self.concat(tbl, ...)
      ___.v.indexed(tbl, 1, false)

      local args = { ... }

      for _, tbl_value in ipairs(args) do
        if type(tbl_value) == "table" then
          for _, value in ipairs(tbl_value) do
            table.insert(tbl, value)
          end
        else
          table.insert(tbl, tbl_value)
        end
      end

      return tbl
    end

    --- Returns a new indexed table with the first n elements removed.
    ---
    ---@param tbl table The indexed table to drop from.
    ---@param n number The number of elements to drop from the start.
    ---@return table result A new indexed table without the first n elements.
    ---@example
    --- ```lua
    --- table.drop({1, 2, 3, 4}, 2)
    --- -- {3, 4}
    --- ```
    function self.drop(tbl, n)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(n, "number", 2, false)
      ___.v.test(n >= 1, n, 2, false)
      return self.slice(tbl, n + 1)
    end

    --- Returns a new indexed table with the last n elements removed.
    ---
    ---@param tbl table The indexed table to drop from.
    ---@param n number The number of elements to drop from the end.
    ---@return table result A new indexed table without the last n elements.
    ---@example
    --- ```lua
    --- table.drop_right({1, 2, 3, 4}, 2)
    --- -- {1, 2}
    --- ```
    function self.drop_right(tbl, n)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(n, "number", 2, false)
      ___.v.test(n >= 1, n, 2, false)
      return self.slice(tbl, 1, #tbl - n)
    end

    --- Fills a range of an indexed table in place with the given value.
    ---
    ---@param tbl table The indexed table to fill.
    ---@param value any The value to fill with.
    ---@param start number|nil The starting index of the range. (Optional. Default is 1.)
    ---@param stop number|nil The ending index of the range. (Optional. Default is the length of the table.)
    ---@return table tbl The modified table.
    ---@example
    --- ```lua
    --- table.fill({1, 2, 3, 4}, 0, 2, 3)
    --- -- {1, 0, 0, 4}
    --- ```
    function self.fill(tbl, value, start, stop)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(value, "any", 2, false)
      ___.v.type(start, "number", 3, true)
      ___.v.type(stop, "number", 4, true)
      if start then ___.v.test(start >= 1, start, 3, false) end
      if stop then ___.v.test(stop >= (start or 1), stop, 4, false) end

      for i = start or 1, stop or #tbl do
        tbl[i] = value
      end
      return tbl
    end

    --- Returns the index of the first element for which the predicate returns
    --- true, or nil if none match.
    ---
    ---@param tbl table The indexed table to search.
    ---@param fn function The predicate called as fn(index, value).
    ---@return number|nil index The index of the first matching element, or nil.
    ---@example
    --- ```lua
    --- table.find({1, 2, 3}, function(i, v) return v == 2 end)
    --- -- 2
    --- ```
    function self.find(tbl, fn)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(fn, "function", 2, false)

      for i = 1, #tbl do
        if fn(i, tbl[i]) then
          return i
        end
      end
      return nil
    end

    --- Returns the index of the last element for which the predicate returns
    --- true, or nil if none match.
    ---
    ---@param tbl table The indexed table to search.
    ---@param fn function The predicate called as fn(index, value).
    ---@return number|nil index The index of the last matching element, or nil.
    ---@example
    --- ```lua
    --- table.find_last({1, 2, 2, 3}, function(i, v) return v == 2 end)
    --- -- 3
    --- ```
    function self.find_last(tbl, fn)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(fn, "function", 2, false)

      for i = #tbl, 1, -1 do
        if fn(i, tbl[i]) then
          return i
        end
      end
      return nil
    end

    --- Flattens an indexed table by one level, expanding any nested tables into
    --- the result.
    ---
    ---@param tbl table The indexed table to flatten.
    ---@return table result A new indexed table flattened one level.
    ---@example
    --- ```lua
    --- table.flatten({1, {2, 3}, 4})
    --- -- {1, 2, 3, 4}
    --- ```
    function self.flatten(tbl)
      ___.v.indexed(tbl, 1, false)

      local result = {}
      for _, v in ipairs(tbl) do
        if type(v) == "table" then
          self.concat(result, v)
        else
          table.insert(result, v)
        end
      end

      return result
    end

    --- Recursively flattens an indexed table, expanding all nested tables at any
    --- depth into the result.
    ---
    ---@param tbl table The indexed table to flatten.
    ---@return table result A new fully flattened indexed table.
    ---@example
    --- ```lua
    --- table.flatten_deeply({1, {2, {3, 4}}})
    --- -- {1, 2, 3, 4}
    --- ```
    function self.flatten_deeply(tbl)
      ___.v.indexed(tbl, 1, false)

      local result = {}
      for _, v in ipairs(tbl) do
        if type(v) == "table" then
          self.concat(result, self.flatten_deeply(v))
        else
          table.insert(result, v)
        end
      end

      return result
    end

    --- Returns a new indexed table containing all but the last element.
    ---
    ---@param tbl table The indexed table to take the initial elements from.
    ---@return table result A new indexed table without the last element.
    ---@example
    --- ```lua
    --- table.initial({1, 2, 3})
    --- -- {1, 2}
    --- ```
    function self.initial(tbl)
      ___.v.indexed(tbl, 1, false)
      if #tbl <= 1 then return {} end
      return self.slice(tbl, 1, #tbl - 1)
    end

    --- Removes all occurrences of the given values from an indexed table in
    --- place.
    ---
    ---@param tbl table The indexed table to pull values from.
    ---@param ... any The values to remove.
    ---@return table tbl The modified table.
    ---@example
    --- ```lua
    --- table.pull({1, 2, 3, 2, 1}, 2)
    --- -- {1, 3, 1}
    --- ```
    function self.pull(tbl, ...)
      ___.v.indexed(tbl, 1, false)

      local args = { ... }
      if #args == 0 then return tbl end

      local removeSet = {}
      for _, value in ipairs(args) do
        removeSet[value] = true
      end

      for i = #tbl, 1, -1 do
        if removeSet[tbl[i]] then
          table.remove(tbl, i)
        end
      end

      return tbl
    end

    --- Reverses the order of the elements of an indexed table in place.
    ---
    ---@param tbl table The indexed table to reverse.
    ---@return table tbl The reversed table.
    ---@example
    --- ```lua
    --- table.reverse({1, 2, 3})
    --- -- {3, 2, 1}
    --- ```
    function self.reverse(tbl)
      ___.v.indexed(tbl, 1, false)

      local len, midpoint = #tbl, math.floor(#tbl / 2)
      for i = 1, midpoint do
        tbl[i], tbl[len - i + 1] = tbl[len - i + 1], tbl[i]
      end
      return tbl
    end

    --- Removes duplicate values from an indexed table in place, keeping the
    --- first occurrence of each value.
    ---
    ---@param tbl table The indexed table to deduplicate.
    ---@return table tbl The modified table with duplicates removed.
    ---@example
    --- ```lua
    --- table.uniq({1, 2, 2, 3, 1})
    --- -- {1, 2, 3}
    --- ```
    function self.uniq(tbl)
      ___.v.indexed(tbl, 1, false)

      local seen = {}
      local writeIndex = 1

      for readIndex = 1, #tbl do
        local value = tbl[readIndex]
        if not seen[value] then
          seen[value] = true
          tbl[writeIndex] = value
          writeIndex = writeIndex + 1
        end
      end

      -- Remove excess elements beyond writeIndex
      for i = #tbl, writeIndex, -1 do
        tbl[i] = nil
      end

      return tbl
    end

    --- Unzips a table of equal-length sub-tables, regrouping their elements by
    --- position into new sub-tables.
    ---
    ---@param tbl table An indexed table of equal-length indexed sub-tables.
    ---@return table result A new table of sub-tables grouped by position.
    ---@example
    --- ```lua
    --- table.unzip({{1, "a"}, {2, "b"}})
    --- -- {{1, 2}, {"a", "b"}}
    --- ```
    function self.unzip(tbl)
      ___.v.indexed(tbl, 1, false)

      local size_of_table = #tbl
      -- Ensure that all sub-tables are of the same length
      local size_of_elements = #tbl[1]
      for _, t in ipairs(tbl) do ___.v.test(size_of_elements == #t, t, 1, false) end

      local num_new_sub_tables = size_of_elements -- yes, this is redundant, but it's more readable
      local new_sub_table_size = size_of_table -- this is the size of the sub-tables
      local result = {}

      for i = 1, num_new_sub_tables do
        result[i] = {}
      end

      for _, source_table in ipairs(tbl) do
        for i, value in ipairs(source_table) do
          table.insert(result[i], value)
        end
      end

      return result
    end

    --- Creates a new table with weak references, controlled by the given mode.
    ---
    ---@param opt string|nil The weak mode: "k", "v", or "kv". (Optional. Default is "v".)
    ---@return table tbl A new table with the specified weak mode.
    ---@example
    --- ```lua
    --- table.new_weak("kv")
    --- -- a table with weak keys and values
    --- ```
    function self.new_weak(opt)
      opt = opt or "v"
      ___.v.test(rex.match(opt, "^(k?v?|v?k?)$"), opt, 1, false)

      return setmetatable({}, { __mode = opt })
    end

    --- Determines whether a table holds weak references.
    ---
    ---@param tbl table The table to check.
    ---@return boolean is_weak True if the table has a weak mode set, otherwise false.
    ---@example
    --- ```lua
    --- table.weak(table.new_weak("v"))
    --- -- true
    --- ```
    function self.weak(tbl)
      ___.v.type(tbl, "table", 1, false)
      local mt = getmetatable(tbl)
      return mt ~= nil and mt.__mode ~= nil
    end

    --- Zips multiple equal-length indexed tables together, grouping elements at
    --- the same position into new sub-tables.
    ---
    ---@param ... table The equal-length indexed tables to zip.
    ---@return table results A new table of position-grouped sub-tables.
    ---@example
    --- ```lua
    --- table.zip({1, 2}, {"a", "b"})
    --- -- {{1, "a"}, {2, "b"}}
    --- ```
    function self.zip(...)
      local tbls = { ... }
      local results = {}

      local size = #tbls[1]
      for _, t in ipairs(tbls) do ___.v.test(size == #t, t, 1, false) end

      for i = 1, size do
        results[i] = {}
        for _, t in ipairs(tbls) do
          table.insert(results[i], t[i])
        end
      end
      return results
    end

    --- Determines whether an indexed table contains the given value.
    ---
    ---@param tbl table The indexed table to search.
    ---@param value any The value to look for.
    ---@return boolean present True if the value is present, otherwise false.
    ---@example
    --- ```lua
    --- table.includes({1, 2, 3}, 2)
    --- -- true
    --- ```
    function self.includes(tbl, value)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(value, "any", 2, false)
      return table.index_of(tbl, value) ~= nil
    end

    local function collect_tables(tbl, extending)
      -- Check if the table is a valid object with a metatable and an __index field
      ___.v.object(tbl, 1, false)
      ___.v.type(extending, "boolean", 2, true)

      -- Set-like table to track visited tables
      local visited = {}
      local tables = {}

      local function add_table(t)
        if not visited[t] then
          table.insert(tables, t)
          visited[t] = true
        end
      end

      -- Start by adding the main table
      add_table(tbl)

      if extending then
        local mt = getmetatable(tbl)
        while mt and mt.__index do
          local extendingTbl = mt.__index
          if type(extendingTbl) == "table" then
            add_table(extendingTbl)
          end
          mt = getmetatable(extendingTbl)
        end
      end

      return tables
    end

    local function get_types(tbl, test)
      ___.v.type(tbl, "table", 1, false)
      ___.v.type(test, "function", 2, false)

      local keys = table.keys(tbl)
      keys = table.n_filter(keys, function(k) return test(tbl, k) end) or {}
      return keys
    end

    local function assemble_results(tables, test)
      local result = {}
      for _, t in ipairs(tables) do
        local keys = get_types(t, test) or {}
        for _, k in ipairs(keys) do
          if not ___.table.includes(result, k) then
            table.insert(result, k)
          end
        end
      end
      return result
    end

    --- Returns the names of all function-valued keys of an object table,
    --- optionally including those inherited through its metatable chain.
    ---
    ---@param tbl table The object table to inspect.
    ---@param extending boolean|nil Whether to include inherited functions. (Optional. Default is false.)
    ---@return table result An indexed table of function names.
    ---@example
    --- ```lua
    --- table.functions(myObject)
    --- -- {"method_a", "method_b"}
    --- ```
    function self.functions(tbl, extending)
      ___.v.object(tbl, 1, false)
      ___.v.type(extending, "boolean", 2, true)

      local tables = collect_tables(tbl, extending) or {}
      local test = function(t, k) return type(t[k]) == "function" end

      return assemble_results(tables, test)
    end
    -- Alias for functions
    self.methods = self.functions

    --- Returns the names of all non-function keys of an object table, optionally
    --- including those inherited through its metatable chain.
    ---
    ---@param tbl table The object table to inspect.
    ---@param extending boolean|nil Whether to include inherited properties. (Optional. Default is false.)
    ---@return table result An indexed table of property names.
    ---@example
    --- ```lua
    --- table.properties(myObject)
    --- -- {"name", "value"}
    --- ```
    function self.properties(tbl, extending)
      ___.v.object(tbl, 1, false)
      ___.v.type(extending, "boolean", 2, true)

      local tables = collect_tables(tbl, extending) or {}
      local test = function(t, k) return type(t[k]) ~= "function" end

      return assemble_results(tables, test)
    end

    --- Determines whether a table is an object, identified by an `object` field
    --- set to true.
    ---
    ---@param tbl table The table to check.
    ---@return boolean is_object True if the table is an object, otherwise false.
    ---@example
    --- ```lua
    --- table.object({object = true})
    --- -- true
    --- ```
    function self.object(tbl)
      ___.v.type(tbl, "table", 1, false)
      return tbl.object == true
    end

    --- Merges the key-value pairs of one associative table into another in
    --- place, overwriting existing keys.
    ---
    ---@param tbl table The associative table to merge into.
    ---@param value table The associative table whose pairs are copied in.
    ---@return table tbl The modified table.
    ---@example
    --- ```lua
    --- table.add({a = 1}, {b = 2})
    --- -- {a = 1, b = 2}
    --- ```
    function self.add(tbl, value)
      ___.v.associative(tbl, 1, false)
      ___.v.associative(value, 2, false)

      for k, v in pairs(value) do
        tbl[k] = v
      end

      return tbl
    end

    --- Inserts the elements of one indexed table into another at the given
    --- index, in place.
    ---
    ---@param tbl1 table The indexed table to insert into.
    ---@param tbl2 table The indexed table whose elements are inserted.
    ---@param index number|nil The position at which to insert. (Optional. Default is the end of tbl1.)
    ---@return table tbl1 The modified table.
    ---@example
    --- ```lua
    --- table.n_add({1, 4}, {2, 3}, 2)
    --- -- {1, 2, 3, 4}
    --- ```
    function self.n_add(tbl1, tbl2, index)
      ___.v.indexed(tbl1, 1, false)
      ___.v.indexed(tbl2, 2, false)
      ___.v.range(index, 1, #tbl1 + 1, 3, true)

      -- We are not adding +1 to the end index because we will be doing +1
      -- in the loop below
      index = index or #tbl1 + 1

      for i = 1, #tbl2 do
        table.insert(tbl1, index + i - 1, tbl2[i])
      end

      return tbl1
    end

    --- Returns a stateful iterator function that walks the elements of an
    --- indexed table, yielding each index and value.
    ---
    ---@param tbl table The indexed table to walk.
    ---@return function iterator An iterator returning index and value on each call.
    ---@example
    --- ```lua
    --- for i, v in table.walk({"a", "b"}) do print(i, v) end
    --- -- 1 a
    --- -- 2 b
    --- ```
    function self.walk(tbl)
      ___.v.indexed(tbl, 1, false)

      local i = 0
      return function()
        i = i + 1
        if tbl[i] then return i, tbl[i] end
      end
    end

    --- Returns a uniformly random element from an indexed table.
    ---
    ---@param list table The indexed table to choose from.
    ---@return any element A randomly chosen element.
    ---@example
    --- ```lua
    --- table.element_of({"a", "b", "c"})
    --- -- "b"
    --- ```
    function self.element_of(list)
      ___.v.type(list, "table", 1, false)

      local max = #list
      return list[math.random(max)]
    end

    --- Returns a randomly chosen key from an associative table, where each
    --- value is the relative weight of its key.
    ---
    ---@param list table An associative table mapping keys to numeric weights.
    ---@return any key A randomly chosen key, weighted by its value.
    ---@example
    --- ```lua
    --- table.element_of_weighted({common = 90, rare = 10})
    --- -- "common"
    --- ```
    function self.element_of_weighted(list)
      ___.v.type(list, "table", 1, false)

      local total = 0
      for _, value in pairs(list) do
        total = total + value
      end

      local random = math.random(total)

      for key, value in pairs(list) do
        random = random - value
        if random <= 0 then
          return key
        end
      end
    end

    local assure_equality_function = function(condition)
      if type(condition) ~= "function" then
        local target = condition
        condition = function(element) return element == target end
      end
      return condition
    end

    --- Determines whether all elements of an indexed table satisfy the
    --- condition. The condition may be a predicate function or a value to match.
    ---
    ---@param tbl table The indexed table to test.
    ---@param condition any A predicate function or a value to compare each element against.
    ---@return boolean matched True if every element satisfies the condition, otherwise false.
    ---@example
    --- ```lua
    --- table.all({2, 4, 6}, function(v) return v % 2 == 0 end)
    --- -- true
    --- ```
    function self.all(tbl, condition)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(condition, "any", 2, false)

      local count = 0

      condition = assure_equality_function(condition)

      local result = table.n_filter(tbl, condition)
      if result then
        count = #result
      end

      return count == #tbl
    end

    --- Determines whether at least one element of an indexed table satisfies the
    --- condition. The condition may be a predicate function or a value to match.
    ---
    ---@param tbl table The indexed table to test.
    ---@param condition any A predicate function or a value to compare each element against.
    ---@return boolean matched True if any element satisfies the condition, otherwise false.
    ---@example
    --- ```lua
    --- table.some({1, 2, 3}, 2)
    --- -- true
    --- ```
    function self.some(tbl, condition)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(condition, "any", 2, false)

      condition = assure_equality_function(condition)

      return #table.n_filter(tbl, condition) > 0
    end

    --- Determines whether no element of an indexed table satisfies the
    --- condition. The condition may be a predicate function or a value to match.
    ---
    ---@param tbl table The indexed table to test.
    ---@param condition any A predicate function or a value to compare each element against.
    ---@return boolean matched True if no element satisfies the condition, otherwise false.
    ---@example
    --- ```lua
    --- table.none({1, 3, 5}, function(v) return v % 2 == 0 end)
    --- -- true
    --- ```
    function self.none(tbl, condition)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(condition, "any", 2, false)

      condition = assure_equality_function(condition)

      return #table.n_filter(tbl, condition) == 0
    end

    --- Determines whether exactly one element of an indexed table satisfies the
    --- condition. The condition may be a predicate function or a value to match.
    ---
    ---@param tbl table The indexed table to test.
    ---@param condition any A predicate function or a value to compare each element against.
    ---@return boolean matched True if exactly one element satisfies the condition, otherwise false.
    ---@example
    --- ```lua
    --- table.one({1, 2, 3}, 2)
    --- -- true
    --- ```
    function self.one(tbl, condition)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(condition, "any", 2, false)

      condition = assure_equality_function(condition)

      return #table.n_filter(tbl, condition) == 1
    end

    --- Counts how many elements of an indexed table satisfy the condition. The
    --- condition may be a predicate function or a value to match.
    ---
    ---@param tbl table The indexed table to test.
    ---@param condition any A predicate function or a value to compare each element against.
    ---@return number count The number of elements that satisfy the condition.
    ---@example
    --- ```lua
    --- table.count({1, 2, 2, 3}, 2)
    --- -- 2
    --- ```
    function self.count(tbl, condition)
      ___.v.indexed(tbl, 1, false)
      ___.v.type(condition, "any", 2, false)

      condition = assure_equality_function(condition)

      return #table.n_filter(tbl, condition)
    end

    --- Returns a new indexed table sorted using natural comparison, leaving the
    --- original table unmodified.
    ---
    ---@param tble table The indexed table to sort.
    ---@return table sorted A new naturally sorted indexed table.
    ---@example
    --- ```lua
    --- table.natural_sort({"item10", "item2", "item1"})
    --- -- {"item1", "item2", "item10"}
    --- ```
    function self.natural_sort(tble)
      ___.v.indexed(tble, 1, false)

      local sorted = {}
      for i = 1, #tble do
        sorted[i] = tble[i]
      end
      table.sort(sorted, ___.string.natural_compare)
      return sorted
    end

    --- Sorts an indexed table. If a comparator function is given, the table is
    --- sorted in place with it; otherwise a new naturally sorted table is
    --- returned.
    ---
    ---@param tbl table The indexed table to sort.
    ---@param arg function|nil A comparator function. (Optional. When omitted, natural sort is used.)
    ---@return table|nil sorted A new naturally sorted table when no comparator is given, otherwise nil.
    ---@example
    --- ```lua
    --- table.sort({3, 1, 2})
    --- -- {1, 2, 3}
    --- ```
    function self.sort(tbl, arg)
      ___.v.indexed(tbl, 1, false)

      if type (arg) == "function" then
        table.sort(tbl, arg)
      else
        return self.natural_sort(tbl)
      end
    end

  end,
  valid = function(___, self)
    return {
      not_empty = function(value, argument_index, nil_allowed)
        assert(type(value) == "table", "Invalid type to argument " ..
          argument_index .. ". Expected table, got " .. type(value) .. " in\n" ..
          ___.get_last_traceback_line())
        if nil_allowed and value == nil then
          return
        end

        local last = ___.get_last_traceback_line()
        assert(not table.is_empty(value), "Invalid value to argument " ..
          argument_index .. ". Expected non-empty in\n" .. last)
      end,

      n_uniform = function(value, expected_type, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = ___.get_last_traceback_line()
        assert(self.n_uniform(value, expected_type),
          "Invalid type to argument " .. argument_index .. ". Expected an " ..
          "indexed table of " .. expected_type .. " in\n" .. last)
      end,
      indexed = function(value, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = ___.get_last_traceback_line()
        assert(self.indexed(value), "Invalid value to argument " ..
          argument_index .. ". Expected indexed table, got " .. type(value) ..
          " in\n" .. last)
      end,
      associative = function(value, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = ___.get_last_traceback_line()

        assert(self.associative(value),
          "Invalid value to argument " .. argument_index .. ". Expected " ..
          "associative table, got " .. type(value) .. " in\n" .. last)
      end,
      object = function(value, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = ___.get_last_traceback_line()
        assert(self.object(value), "Invalid value to argument " ..
          argument_index .. ". Expected object, got " .. type(value) ..
          " in\n" .. last)
      end,
      option = function(value, options, argument_index)
        ___.v.type(value, "any", argument_index, false)
        ___.v.indexed(options, argument_index, false)
        ___.v.type(argument_index, "number", 3, false)

        local last = ___.get_last_traceback_line()
        assert(table.index_of(options, value) ~= nil, "Invalid value to " ..
          "argument " .. argument_index .. ". Expected one of " ..
          table.concat(options, ", ") .. ", got " .. value .. " in\n" .. last)
      end
    }
  end,
})
