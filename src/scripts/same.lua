local SameClass = Glu.glass.register({
  name = "same",
  class_name = "SameClass",
  dependencies = { "table" },
  setup = function(___, self)
    --- Checks if two values are the same, including special cases for NaN and zero.
    ---@param value1 any The first value to compare.
    ---@param value2 any The second value to compare.
    ---@return boolean same True if the values are the same, false otherwise.
    function self.value_zero(value1, value2)
      ___.v.type(value1, "any", 1, false)
      ___.v.type(value2, "any", 2, false)

      -- If types are different, return false
      if type(value1) ~= type(value2) then
        return false
      end

      -- If type is 'number', handle special cases for NaN and zero
      if type(value1) == "number" then
        if value1 ~= value1 and value2 ~= value2 then -- Check if both x and y are NaN
          return true
        elseif value1 == 0 and value2 == 0 then
          -- Handle +0 and -0
          return true
        elseif value1 == value2 then
          return true
        else
          return false
        end
      end

      -- For non-number values, use a simple equality check
      return value1 == value2
    end

    --- Checks if two values are the same, including special cases for NaN and zero.
    ---@param value1 any The first value to compare.
    ---@param value2 any The second value to compare.
    ---@return boolean same True if the values are the same, false otherwise.
    function self.value(value1, value2)
      ___.v.type(value1, "any", 1, false)
      ___.v.type(value2, "any", 2, false)

      -- If types are different, return false
      if type(value1) ~= type(value2) then
        return false
      end

      -- If type is 'number', handle special cases for NaN and zero
      if type(value1) == "number" then
        if value1 ~= value1 and value2 ~= value2 then -- Check if both x and y are NaN
          return true
        elseif value1 == 0 and value2 == 0 then
          return true
        elseif value1 == value2 then
          return true
        else
          return false
        end
      end

      -- For non-number values, use a simple equality check
      return value1 == value2
    end
  end
})
