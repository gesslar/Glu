local NumberClass = Glu.glass.register({
  name = "number",
  class_name = "NumberClass",
  dependencies = { "table" },
  setup = function(___, self)
    --- Rounds a number to a specified number of decimal places.
    ---
    ---@param num number The number to round.
    ---@param digits number The number of digits to round to. (Optional. Default is 0.)
    ---@return number rounded The rounded number.
    ---@example
    --- ```lua
    --- number.round(3.14159, 2)
    --- -- 3.14
    --- ```
    function self.round(num, digits)
      ___.v.type(num, "number", 1, false)
      ___.v.type(digits, "number", 2, true)

      digits = digits or 0

      local mult = 10 ^ digits
      return math.floor(num * mult + 0.5) / mult
    end

    --- Clamps a number within a range.
    ---@param num number The number to clamp.
    ---@param min number The minimum allowed value.
    ---@param max number The maximum allowed value.
    ---@return number clamped The clamped number.
    ---@example
    --- ```lua
    --- number.clamp(10, 1, 100)
    --- -- 10
    --- ```
    function self.clamp(num, min, max)
      ___.v.type(num, "number", 1, false)
      ___.v.type(min, "number", 2, false)
      ___.v.type(max, "number", 3, false)

      return math.max(min, math.min(num, max))
    end

    --- Linearly interpolates between two numbers.
    ---@param a number The starting value.
    ---@param b number The ending value.
    ---@param t number The interpolation factor (between 0 and 1).
    ---@return number interpolated The interpolated value.
    ---@example
    --- ```lua
    --- number.lerp(0, 100, 0.5)
    --- -- 50
    --- ```
    function self.lerp(a, b, t)
      ___.v.type(a, "number", 1, false)
      ___.v.type(b, "number", 2, false)
      ___.v.type(t, "number", 3, false)
      ___.v.test(t >= 0 and t <= 1, t, 3, false, "Interpolation factor should be between 0 and 1")

      return a + (b - a) * t
    end

    --- Smoothly interpolates between two numbers using a cubic function.
    ---@param start number The starting value.
    ---@param end_val number The ending value.
    ---@param t number The interpolation factor (between 0 and 1).
    ---@return number interpolated The interpolated value.
    ---@example
    --- ```lua
    --- number.lerp_smooth(0, 100, 0.5)
    --- -- 50
    --- ```
    function self.lerp_smooth(start, end_val, t)
      ___.v.type(start, "number", 1, false)
      ___.v.type(end_val, "number", 2, false)
      ___.v.type(t, "number", 3, false)
      ___.v.test(t >= 0 and t <= 1, t, 3, false)

      -- Smooth step (cubic)
      t = t * t * (3 - 2 * t)
      return start + (end_val - start) * t
    end

    --- Smoothly interpolates between two numbers using a quintic function.
    ---@param start number The starting value.
    ---@param end_val number The ending value.
    ---@param t number The interpolation factor (between 0 and 1).
    ---@return number interpolated The interpolated value.
    ---@example
    --- ```lua
    function self.lerp_smoother(start, end_val, t)
      ___.v.type(start, "number", 1, false)
      ___.v.type(end_val, "number", 2, false)
      ___.v.type(t, "number", 3, false)
      ___.v.test(t >= 0 and t <= 1, t, 3, false)

      -- Smoother step (quintic)
      t = t * t * t * (t * (t * 6 - 15) + 10)
      return start + (end_val - start) * t
    end

    --- Eases a number in towards a target value.
    ---@param start number The starting value.
    ---@param end_val number The target value.
    ---@param t number The interpolation factor (between 0 and 1).
    ---@return number eased The eased value.
    ---@example
    --- ```lua
    function self.lerp_ease_in(start, end_val, t)
      ___.v.type(start, "number", 1, false)
      ___.v.type(end_val, "number", 2, false)
      ___.v.type(t, "number", 3, false)
      ___.v.test(t >= 0 and t <= 1, t, 3, false)

      -- Quadratic ease in
      t = t * t
      return start + (end_val - start) * t
    end

    --- Eases a number out towards a target value.
    ---@param start number The starting value.
    ---@param end_val number The target value.
    ---@param t number The interpolation factor (between 0 and 1).
    ---@return number eased The eased value.
    ---@example
    --- ```lua
    function self.lerp_ease_out(start, end_val, t)
      ___.v.type(start, "number", 1, false)
      ___.v.type(end_val, "number", 2, false)
      ___.v.type(t, "number", 3, false)
      ___.v.test(t >= 0 and t <= 1, t, 3, false)

      -- Quadratic ease out
      t = t * (2 - t)
      return start + (end_val - start) * t
    end

    --- Maps a number from one range to another.
    ---@param value number The input number.
    ---@param in_min number The minimum of the input range.
    ---@param in_max number The maximum of the input range.
    ---@param out_min number The minimum of the output range.
    ---@param out_max number The maximum of the output range.
    ---@return number mapped The mapped number.
    ---@example
    --- ```lua
    --- number.map(50, 0, 100, 0, 100)
    --- -- 50
    --- ```
    function self.map(value, in_min, in_max, out_min, out_max)
      ___.v.type(value, "number", 1, false)
      ___.v.type(in_min, "number", 2, false)
      ___.v.type(in_max, "number", 3, false)
      ___.v.type(out_min, "number", 4, false)
      ___.v.type(out_max, "number", 5, false)

      return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
    end

    --- Tests a number to see if it is positive, negative, or zero.
    ---@param num number The number to check.
    ---@return boolean is_positive True if the number is positive, false otherwise.
    ---@example
    --- ```lua
    --- number.positive(10)
    --- -- true
    --- ```
    function self.positive(num)
      ___.v.type(num, "number", 1, false)

      return num > 0
    end

    --- Checks if two numbers are approximately equal within a percentage tolerance.
    ---@param a number The first number.
    ---@param b number The second number.
    ---@param percent_tolerance number The percentage allowed difference (default is 5%).
    ---@return boolean ok True if the numbers are approximately equal, false otherwise.
    ---@example
    --- ```lua
    --- number.is_approximate(10, 11, 10)
    --- -- true
    --- ```
    function self.is_approximate(a, b, percent_tolerance)
      ___.v.type(a, "number", 1, false)
      ___.v.type(b, "number", 2, false)
      ___.v.type(percent_tolerance, "number", 3, true)

      percent_tolerance = percent_tolerance or 5 -- Default to 5%
      local tolerance = math.abs(a) * (percent_tolerance / 100)
      return math.abs(a - b) <= tolerance
    end

    --- Returns the minimum value in a list of numbers or a table.
    ---@param ... number|table[] Either a list of numbers or a single table of numbers.
    ---@return number result The minimum value.
    ---@example
    --- ```lua
    --- number.min(1, 2, 3)
    --- -- 1
    --- ```
    function self.min(...)
      local args = ___.table.n_cast(...)
      ___.v.n_uniform(args, "number", 1, false)

      -- Calculate the minimum value
      local result = math.huge
      for _, num in ipairs(args) do
        result = math.min(result, num)
      end

      return result
    end

    --- Returns the maximum value in a list of numbers or a table of numbers.
    ---@param ... number|number[] Either a list of numbers or a single table of numbers.
    ---@return number result The maximum value.
    ---@example
    --- ```lua
    --- number.max(1, 2, 3)
    --- -- 3
    --- ```
    function self.max(...)
      local args = ___.table.n_cast(...)
      ___.v.n_uniform(args, "number", 1, false)

      -- Calculate the maximum value
      local result = -math.huge
      for _, num in ipairs(args) do
        result = math.max(result, num)
      end

      return result
    end

    --- Sums a list of numbers.
    ---@param ... number[] The numbers to sum.
    ---@return number sum The sum of the numbers.
    ---@example
    --- ```lua
    --- number.sum(1, 2, 3)
    --- -- 6
    --- ```
    function self.sum(...)
      local args = ___.table.n_cast(...)
      ___.v.n_uniform(args, "number", 1, false)
      return ___.table.reduce(args, function(acc, num) return acc + num end, 0)
    end

    --- Returns a random number between a minimum and maximum value.
    ---@param min number The minimum value.
    ---@param max number The maximum value.
    ---@return number random The random number.
    ---@example
    --- ```lua
    --- number.random_clamp(0, 100)
    --- -- 50
    --- ```
    function self.random_clamp(min, max)
      ___.v.type(min, "number", 1, false)
      ___.v.type(max, "number", 2, false)

      return math.random() * (max - min) + min
    end

    --- Checks if a number is between two values (inclusive)
    ---@param num number The number to check
    ---@param min number The minimum value
    ---@param max number The maximum value
    ---@return boolean is_between True if the number is between min and max
    ---@example
    --- ```lua
    --- number.is_between(5, 1, 10)
    --- -- true
    --- ```
    function self.is_between(num, min, max)
      ___.v.type(num, "number", 1, false)
      ___.v.type(min, "number", 2, false)
      ___.v.type(max, "number", 3, false)

      return num >= min and num <= max
    end

    ---@param num number The number to check
    ---@return number sign The sign (-1, 0, or 1)
    ---@example
    --- ```lua
    --- number.sign(-5)
    --- -- -1
    --- ```
    function self.sign(num)
      ___.v.type(num, "number", 1, false)

      return num > 0 and 1 or (num < 0 and -1 or 0)
    end

    --- Calculates the average (mean) of a list of numbers
    ---@param ... number|number[] Either a list of numbers or a single table of numbers
    ---@return number average The average value
    ---@example
    --- ```lua
    --- number.average(1, 2, 3)
    --- -- 2
    --- ```
    function self.average(...)
      local values = ___.table.n_cast(...)
      ___.v.n_uniform(values, "number", 1, false)
      return self.sum(values) / #values
    end

    --- Constrains a number to a certain precision
    ---@param num number The number to constrain
    ---@param precision number The precision (e.g., 0.1, 0.01, etc.)
    ---@return number constrained The constrained number
    ---@example
    --- ```lua
    --- number.constrain(3.14159, 0.01)
    --- -- 3.14
    --- ```
    function self.constrain(num, precision)
      ___.v.type(num, "number", 1, false)
      ___.v.type(precision, "number", 2, false)

      return math.floor(num / precision + 0.5) * precision
    end

    --- Calculates what percentage one number is of another
    ---@param value number The current value
    ---@param total number The total value
    ---@param round_digits? number Optional number of decimal places to round to
    ---@return number result The percentage
    ---@example
    --- ```lua
    --- number.percent_of(25, 20)
    --- -- 5
    --- ```
    function self.percent_of(numerator, denominator, round_digits)
      ___.v.type(numerator, "number", 1, false)
      ___.v.type(denominator, "number", 2, false)
      ___.v.type(round_digits, "number", 3, true)

      local result = (numerator * 100) / denominator
      if round_digits then
        return self.round(result, round_digits)
      end
      return result
    end

    --- Calculates what number is a certain percentage of another
    ---@param percent number The percentage
    ---@param total number The total value
    ---@param round_digits? number Optional number of decimal places to round to
    ---@return number result The resulting value
    ---@example
    --- ```lua
    --- number.percent(25, 100)
    --- -- 25
    --- number.percent(5, 20)
    --- -- 1
    --- ```
    function self.percent(percent, total, round_digits)
      ___.v.type(percent, "number", 1, false)
      ___.v.type(total, "number", 2, false)
      ___.v.type(round_digits, "number", 3, true)

      local result = (percent * total) / 100
      if round_digits then
        return self.round(result, round_digits)
      end
      return result
    end

    --- Normalizes a number to a 0-1 range
    ---@param num number The number to normalize
    ---@param min number The minimum value of the range
    ---@param max number The maximum value of the range
    ---@return number normalized The normalized value (0-1)
    ---@example
    --- ```lua
    --- number.normalize(50, 0, 100)
    --- -- 0.5
    --- ```
    function self.normalize(num, min, max)
      return self.map(num, min, max, 0, 1)
    end

    --- Calculates the arithmetic mean of a list of numbers
    ---@param ... number|number[] Either a list of numbers or a single table of numbers
    ---@return number mean The arithmetic mean
    ---@example
    --- ```lua
    --- number.mean(1, 2, 3)
    --- -- 2
    --- ```
    function self.mean(...)
      local values = ___.table.n_cast(...)
      ___.v.n_uniform(values, "number", 1, false)
      return self.sum(values) / #values
    end
  end,
  valid = function(___, self)
    return {
      range = function(value, min, max, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = ___.v.get_last_traceback_line()
        assert(value >= min and value <= max, "Invalid value to argument " ..
          argument_index .. ". Expected " .. min .. " to " .. max .. ", " ..
          "got " .. value .. " in\n" .. last)
      end
    }
  end
})
