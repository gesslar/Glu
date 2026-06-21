local VersionClass = Glu.glass.register({
  name = "version",
  class_name = "VersionClass",
  dependencies = { "table" },
  setup = function(___, self)
    --- Returns 1 if one is greater than two, -1 if one is less than two, and 0 if they are the same
    local function _compare(one, two)
      if one == two then
        return 0
      end

      -- Try numeric comparison first so "9" < "10" works correctly
      local n1, n2 = tonumber(one), tonumber(two)
      if n1 and n2 then
        return n1 < n2 and -1 or 1
      end

      return one < two and -1 or 1
    end

    --- Compares two version strings. They can be a number, or a string. If a
    --- string, then it can be a string representation of a number or a semver
    --- string.
    ---
    ---@param version1 string|number The first version string or number.
    ---@param version2 string|number The second version string or number.
    ---@return number result 1 if version1 is greater than version2, -1 if version1 is less than version2, and 0 if they are the same.
    ---@example
    --- ```lua
    --- version.compare("1.0.0", "2.0.0")
    --- -- -1
    --- ```
    function self.compare(version1, version2)
      -- The versions must be of the same type
      ___.v.test(type(version1) == "string" or type(version1) == "number", "Expected a string or number.", 1)
      ___.v.test(type(version2) == "string" or type(version2) == "number", "Expected a string or number.", 2)
      ___.v.same_type(version1, version2)

      version1 = tostring(version1)
      version2 = tostring(version2)

      -- Split the versions into parts
      local version1_parts = version1:split("%.") or {}
      local version2_parts = version2:split("%.") or {}

      ___.v.test(type(version1_parts) == "table", "Expected a string.", 1)
      ___.v.test(type(version2_parts) == "table", "Expected a string.", 2)

      ___.v.test(#version1_parts == #version2_parts, "Expected arguments 1 and 2 to have the same number of parts.", 1)

      for i = 1, #version1_parts do
        local result = _compare(version1_parts[i], version2_parts[i])
        if result ~= 0 then
          return result
        end
      end

      return 0
    end
  end
})
