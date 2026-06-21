local ColourClass = Glu.glass.register({
  class_name = "ColourClass",
  name = "colour",
  dependencies = { "number" },
  setup = function(___, self)
    local v = self.v
    --- Interpolates between two RGB colours based on a step value. Functionally,
    --- it takes two colours and returns a third colour somewhere between the
    --- two colours, based on the step value. Generally used to fade between two
    --- colours. The step value is the current transition percentage as a whole
    --- number between the two colours, with 0 being the first colour and 100 being
    --- the second colour.
    ---
    --- Available interpolation methods are:
    --- - linear
    --- - smooth (default)
    --- - smoother
    --- - ease_in
    --- - ease_out
    ---
    ---@example
    --- ```lua
    --- colour.interpolate({255, 0, 0}, {0, 0, 255}, 50)
    --- -- {127, 0, 127}
    --- ```
    ---@param rgb1 table The first RGB colour as a table with three elements: red, green, and blue.
    ---@param rgb2 table The second RGB colour as a table with three elements: red, green, and blue.
    ---@param factor number The step value between 0 and 1.
    ---@param method string The interpolation method to use. (Optional, defaults to "smooth")
    ---@returns table The interpolated RGB colour as a table with three elements: red, green, and blue.
    function self.interpolate(rgb1, rgb2, factor, method)
      ___.v.rgb_table(rgb1, 1, false)
      ___.v.rgb_table(rgb2, 2, false)
      ___.v.type(factor, "number", 3, false)
      ___.v.range(factor, 0, 100, 3, false)

      -- Available interpolation methods
      local lerps = {
        linear = ___.number.lerp,
        smooth = ___.number.lerp_smooth,
        smoother = ___.number.lerp_smoother,
        ease_in = ___.number.lerp_ease_in,
        ease_out = ___.number.lerp_ease_out
      }

      -- Default to smooth as it often looks better for colors
      method = method or 'smooth'

      -- Validate method if provided
      local valid_methods = table.keys(lerps)
      local lerp_func = lerps[method]
      ___.v.test(lerp_func ~= nil,
        f "Invalid interpolation method: {method}. Must be one of: " ..
        table.concat(valid_methods, ", "), 4, false)

      local hsl1 = self.rgb_to_hsl(rgb1)
      local hsl2 = self.rgb_to_hsl(rgb2)
      local t = factor / 100

      -- Special handling for hue to ensure we take shortest path around the color wheel
      local h1, h2 = hsl1[1], hsl2[1]
      local diff = h2 - h1
      if diff > 180 then
        h2 = h2 - 360
      elseif diff < -180 then
        h2 = h2 + 360
      end

      local h = lerp_func(h1, h2, t) % 360
      local s = lerp_func(hsl1[2], hsl2[2], t)
      local l = lerp_func(hsl1[3], hsl2[3], t)

      return self.hsl_to_rgb({ h, s, l })
    end

    --- Converts an RGB colour to HSL.
    --- Returns hue in degrees (0-360) and saturation and lightness as percentages (0-100).
    ---
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns table The HSL colour as a table with three elements: hue, saturation, and lightness.
    ---@example
    --- ```lua
    --- colour.rgb_to_hsl({255, 0, 0})
    --- ```
    function self.rgb_to_hsl(rgb)
      ___.v.rgb_table(rgb, 1, false)

      local r, g, b = rgb[1] / 255, rgb[2] / 255, rgb[3] / 255
      local max, min = math.max(r, g, b), math.min(r, g, b)
      local h, s, l = 0, 0, (max + min) / 2

      if max ~= min then
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)

        if max == r then
          h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
          h = (b - r) / d + 2
        else
          h = (r - g) / d + 4
        end

        h = h / 6
      end

      -- Convert to degrees/percentages and ensure numbers
      return {
        math.floor(h * 360 + 0.5),
        math.floor(s * 100 + 0.5),
        math.floor(l * 100 + 0.5)
      }
    end

    --- Converts an RGB colour to a hex string.
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param background table An optional background RGB colour as a table with three elements: red, green, and blue.
    ---@returns string The hex string.
    ---
    ---@example
    --- ```lua
    --- colour.to_hex({255, 255, 255})
    --- -- "#ffffff"
    --- colour.to_hex({255, 255, 255}, {0, 0, 0})
    --- -- "#ffffff,000000"
    --- ```
    function self.to_hex(rgb, background)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.rgb_table(background, 2, true)

      -- Convert RGB to hex format
      local function to_hex_part(r, g, b)
        return string.format("%02x%02x%02x", r, g, b)
      end

      if background then
        -- If there's a background color, return format for "fg,bg"
        return "#" .. to_hex_part(rgb[1], rgb[2], rgb[3]) .. "," ..
            to_hex_part(background[1], background[2], background[3])
      else
        -- Just foreground color
        return "#" .. to_hex_part(rgb[1], rgb[2], rgb[3])
      end
    end

    --- Converts an HSL colour to an RGB colour.
    ---@param hsl table The HSL colour as a table with three elements: hue, saturation, and lightness.
    ---@returns table The RGB colour as a table with three elements: red, green, and blue.
    ---
    ---@example
    --- ```lua
    --- colour.hsl_to_rgb({180, 50, 50})
    --- -- {127, 127, 127}
    --- ```
    function self.hsl_to_rgb(hsl)
      ___.v.hsl_table(hsl, 1, false)

      local h, s, l = hsl[1] / 360, hsl[2] / 100, hsl[3] / 100

      local function hue_to_rgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1 / 6 then return p + (q - p) * 6 * t end
        if t < 1 / 2 then return q end
        if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
        return p
      end

      local r, g, b

      if s == 0 then
        r, g, b = l, l, l
      else
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q

        r = hue_to_rgb(p, q, h + 1 / 3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1 / 3)
      end

      -- Ensure we return numbers
      return {
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5)
      }
    end

    --- Determines if a colour is a light colour.
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns boolean True if the colour is light, false otherwise.
    ---
    ---@example
    --- ```lua
    --- colour.is_light({255, 255, 255})
    --- -- true
    --- ```
    function self.is_light(rgb)
      ___.v.rgb_table(rgb, 1, false)

      local r = rgb[1] / 255
      local g = rgb[2] / 255
      local b = rgb[3] / 255
      local luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
      return luminance > 0.5
    end

    --- Lightens or darkens a colour by a given amount.
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param amount number The amount to adjust the colour by.
    ---@param lighten boolean Whether to lighten (true) or darken (false) the colour.
    ---@returns table The adjusted RGB colour as a table with three elements: red, green, and blue.
    function self.adjust_colour(rgb, amount, lighten)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.type(amount, "number", 2, true)

      amount = ___.number.clamp(amount or 30, 0, 255)

      local direction = lighten and 1 or -1

      return {
        math.floor(___.number.clamp(rgb[1] + direction * amount, 0, 255)),
        math.floor(___.number.clamp(rgb[2] + direction * amount, 0, 255)),
        math.floor(___.number.clamp(rgb[3] + direction * amount, 0, 255))
      }
    end

    --- Lightens a colour by a given amount.
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param amount number The amount to lighten the colour by. (Optional, defaults to 30)
    ---@returns table The lightened RGB colour as a table with three elements: red, green, and blue.
    ---
    ---@example
    --- ```lua
    --- colour.lighten({100,100,100},50)
    --- -- {150, 150, 150}
    --- ```
    function self.lighten(rgb, amount)
      return self.adjust_colour(rgb, amount, true)
    end

    --- Darkens a colour by a given amount.
    ---
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param amount number The amount to darken the colour by. (Optional, defaults to 30)
    ---@returns table The darkened RGB colour as a table with three elements: red, green, and blue.
    ---
    ---@example
    --- ```lua
    --- colour.darken({100,100,100},50)
    --- -- {50, 50, 50}
    --- ```
    function self.darken(rgb, amount)
      return self.adjust_colour(rgb, amount, false)
    end

    --- Lightens or darkens the first colour by a given amount based on a comparison with the second colour.
    --- If the colours are already contrasting, the original colour is returned.
    ---@param rgb_colour table The RGB colour to adjust, as a table with three elements: red, green, and blue.
    ---@param rgb_compare table The RGB colour to compare against, as a table with three elements: red, green, and blue.
    ---@param amount number The amount to lighten or darken the colour by. (Optional, defaults to 85)
    ---@returns table The adjusted RGB colour as a table with three elements: red, green, and blue. Unless the colours are already constrasted, in which case the original colour is returned.
    ---
    ---@example
    --- ```lua
    --- colour.lighten_or_darken({100,100,100}, {255,255,255}, 50)
    --- -- {100, 100, 100}
    ---
    --- -- If you want to a light or dark version of the same colour, you can use this:
    --- -- This is useful if you aren't sure what the colour is, but you want to
    --- -- have a contrasting shade.
    --- colour.lighten_or_darken({255,255,255}, {255,255,255}, 50)
    --- -- {205, 205, 205}
    --- ```
    function self.lighten_or_darken(rgb_colour, rgb_compare, amount)
      ___.v.type(amount, "number", 3, true)

      amount = amount or 85

      local colour_is_light = self.is_light(rgb_colour)
      local compare_is_light = self.is_light(rgb_compare)

      if colour_is_light and compare_is_light then
        return self.darken(rgb_colour, amount)
      elseif not colour_is_light and not compare_is_light then
        return self.lighten(rgb_colour, amount)
      else
        return rgb_colour
      end
    end

    --- Returns the complementary colour of a given colour.
    ---@example
    --- ```lua
    --- colour.complementary({ 150, 150, 150 })
    --- -- { 105, 105, 105 }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns table The complementary RGB colour as a table with three elements: red, green, and blue.
    function self.complementary(rgb)
      ___.v.rgb_table(rgb, 1, false)

      local hsl = self.rgb_to_hsl(rgb)
      -- Rotate hue by 180 degrees for true complement
      hsl[1] = (hsl[1] + 180) % 360

      return self.hsl_to_rgb(hsl)
    end

    --- Converts a colour to its grayscale equivalent.
    ---@example
    --- ```lua
    --- colour.grayscale({ 35, 50, 100 })
    --- -- { 62, 62, 62 }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns table The grayscale RGB colour as a table with three elements: red, green, and blue.
    function self.grayscale(rgb)
      ___.v.rgb_table(rgb, 1, false)

      local gray = math.floor((rgb[1] + rgb[2] + rgb[3]) / 3 + 0.5)
      return { gray, gray, gray }
    end

    --- Adjusts the saturation of a colour by a given factor.
    ---@example
    --- ```lua
    --- colour.adjust_saturation({ 35, 50, 100 }, 0.5)
    --- -- { 48, 55, 80 }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param factor number A factor between 0 (fully desaturated) and 1 (fully saturated).
    ---@returns table The adjusted RGB colour as a table with three elements: red, green, and blue.
    function self.adjust_saturation(rgb, factor)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.type(factor, "number", 2, true)

      local gray = (rgb[1] + rgb[2] + rgb[3]) / 3

      return {
        math.floor(gray + (rgb[1] - gray) * factor),
        math.floor(gray + (rgb[2] - gray) * factor),
        math.floor(gray + (rgb[3] - gray) * factor)
      }
    end

    --- Generates a random RGB colour.
    ---@example
    --- ```lua
    --- colour.random()
    --- -- { 123, 45, 67 }
    --- ```
    ---@returns table A random RGB colour as a table with three elements: red, green, and blue.
    function self.random()
      return { math.random(0, 255), math.random(0, 255), math.random(0, 255) }
    end

    --- Generates a random shade of a given colour within a range.
    ---@example
    --- ```lua
    --- colour.random_shade({ 100, 100, 100 }, 50)
    --- -- { 150, 150, 150 }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param range number The range to adjust the colour by (e.g., 50 means +/- 50 for R, G, and B). (Optional, defaults to 50)
    ---@returns table A random RGB colour that is a shade of the given colour.
    function self.random_shade(rgb, range)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.type(range, "number", 2, true)

      range = range or 50

      local r = math.random(math.max(0, rgb[1] - range), math.min(255, rgb[1] + range))
      local g = math.random(math.max(0, rgb[2] - range), math.min(255, rgb[2] + range))
      local b = math.random(math.max(0, rgb[3] - range), math.min(255, rgb[3] + range))
      return { r, g, b }
    end

    --- Generates the triad colours of a given colour. Does not return the
    --- original colour, but two returned colours that are considered tritones of
    --- the original colour.
    ---@example
    --- ```lua
    --- colour.triad({ 100, 100, 100 })
    --- -- { { 15, 204, 204 }, { 100, 204, 204 } }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns table A table of RGB colours that are the triad of the given colour.
    function self.triad(rgb)
      ___.v.rgb_table(rgb, 1, false)

      local hsl = self.rgb_to_hsl(rgb)
      -- Generate two colors 120 degrees apart in hue
      return {
        self.hsl_to_rgb({ (hsl[1] + 120) % 360, hsl[2], hsl[3] }),
        self.hsl_to_rgb({ (hsl[1] + 240) % 360, hsl[2], hsl[3] })
      }
    end

    --- Generates the analogous colours of a given colour.
    --- The analogous colours are generated by rotating the hue of the given
    --- colour by a given angle.
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param angle number The angle to separate the analogous colours by. (Optional, defaults to 30)
    ---@returns table A table of RGB colours that are analogous to the given colour.
    ---@example
    --- ```lua
    --- colour.analogous({ 100, 100, 100 })
    --- -- { { 70, 100, 100 }, { 100, 100, 100 }, { 130, 100, 100 } }
    --- ```
    function self.analogous(rgb, angle)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.type(angle, "number", 2, true)

      angle = angle or 30 -- Default 30 degree separation
      local hsl = self.rgb_to_hsl(rgb)

      return {
        self.hsl_to_rgb({ (hsl[1] - angle) % 360, hsl[2], hsl[3] }),
        rgb, -- Original color in the middle
        self.hsl_to_rgb({ (hsl[1] + angle) % 360, hsl[2], hsl[3] })
      }
    end

    --- Generates the split complement colours of a given colour.
    ---@example
    --- ```lua
    --- colour.split_complement({ 100, 100, 100 })
    --- -- { { 15, 204, 204 }, { 100, 204, 204 } }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param angle number The angle to separate the split complement colours by. (Optional, defaults to 30)
    ---@returns table A table of RGB colours that are the split complement of the given colour.
    function self.split_complement(rgb, angle)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.type(angle, "number", 2, true)

      angle = angle or 30 -- Default split angle
      local hsl = self.rgb_to_hsl(rgb)
      local complement_h = (hsl[1] + 180) % 360

      return {
        self.hsl_to_rgb({ (complement_h - angle) % 360, hsl[2], hsl[3] }),
        self.hsl_to_rgb({ (complement_h + angle) % 360, hsl[2], hsl[3] })
      }
    end

    --- Generates a series of monochromatic colours based on a given colour.
    ---@example
    --- ```lua
    --- colour.monochrome({ 100, 100, 100 })
    --- -- { { 100, 100, 100 }, { 100, 100, 100 }, { 100, 100, 100 } }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@param steps number The number of variations to generate. (Optional, defaults to 5)
    ---@returns table A table of RGB colours that are monochromatic variations of the given colour.
    function self.monochrome(rgb, steps)
      ___.v.rgb_table(rgb, 1, false)
      ___.v.type(steps, "number", 2, true)

      steps = steps or 5 -- Default number of variations
      local hsl = self.rgb_to_hsl(rgb)
      local results = {}

      for i = 0, steps - 1 do
        -- Vary both lightness and saturation
        local s = ___.number.clamp(hsl[2] + (i - (steps / 2)) * 10, 0, 100)
        local l = ___.number.clamp(hsl[3] + (i - (steps / 2)) * 10, 0, 100)
        table.insert(results, self.hsl_to_rgb({ hsl[1], s, l }))
      end

      return results
    end

    --- Generates the tetrad colours of a given colour.
    ---@example
    --- ```lua
    --- colour.tetrad({ 100, 100, 100 })
    --- -- { { 100, 100, 100 }, { 100, 100, 100 }, { 100, 100, 100 }, { 100, 100, 100 } }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns table A table of RGB colours that are the tetrad of the given colour.
    function self.tetrad(rgb)
      ___.v.rgb_table(rgb, 1, false)

      local hsl = self.rgb_to_hsl(rgb)
      return {
        rgb, -- Original color
        self.hsl_to_rgb({ (hsl[1] + 90) % 360, hsl[2], hsl[3] }),
        self.hsl_to_rgb({ (hsl[1] + 180) % 360, hsl[2], hsl[3] }),
        self.hsl_to_rgb({ (hsl[1] + 270) % 360, hsl[2], hsl[3] })
      }
    end

    --- Calculates the contrast ratio between two colours.
    ---@example
    --- ```lua
    --- colour.contrast_ratio({ 100, 100, 100 }, { 0, 0, 0 })
    --- -- 12.0
    --- ```
    ---@param rgb1 table The first RGB colour as a table with three elements: red, green, and blue.
    ---@param rgb2 table The second RGB colour as a table with three elements: red, green, and blue.
    ---@returns number The contrast ratio between the two colours.
    function self.contrast_ratio(rgb1, rgb2)
      ___.v.rgb_table(rgb1, 1, false)
      ___.v.rgb_table(rgb2, 2, false)

      -- Convert RGB to relative luminance
      local function luminance(rgb)
        local r, g, b = rgb[1] / 255, rgb[2] / 255, rgb[3] / 255
        -- Convert RGB to linear space
        r = r <= 0.03928 and r / 12.92 or ((r + 0.055) / 1.055) ^ 2.4
        g = g <= 0.03928 and g / 12.92 or ((g + 0.055) / 1.055) ^ 2.4
        b = b <= 0.03928 and b / 12.92 or ((b + 0.055) / 1.055) ^ 2.4
        -- Calculate luminance
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
      end

      local l1 = luminance(rgb1)
      local l2 = luminance(rgb2)
      local lighter = math.max(l1, l2)
      local darker = math.min(l1, l2)

      return (lighter + 0.05) / (darker + 0.05)
    end

    --- Calculates the contrasting colour based on the luminance of a given colour.
    ---@example
    --- ```lua
    --- colour.contrast({ 100, 100, 100 })
    --- -- { 0, 0, 0 }
    --- ```
    ---@param rgb table The RGB colour as a table with three elements: red, green, and blue.
    ---@returns table The contrasting colour as a table with three elements: red, green, and blue.
    function self.contrast(rgb)
      ___.v.rgb_table(rgb, 1, false)

      -- Convert RGB to HSL
      local hsl = self.rgb_to_hsl(rgb)

      -- Invert the lightness to get the contrasting colour
      hsl[3] = 100 - hsl[3]

      -- Convert back to RGB
      return self.hsl_to_rgb(hsl)
    end
  end,
  -- Validations
  valid = function(___, self)
    return {
      rgb_table = function(colour, argument_index, nil_allowed)
        if nil_allowed and colour == nil then return end

        local last = ___.v.get_last_traceback_line()

        ___.v.type(colour, "table", argument_index, nil_allowed)
        assert(#colour == 3,
          "Invalid number of elements to argument " ..
          argument_index .. ". Expected 3, got " .. #colour .. " in\n" .. last)
        assert(type(colour[1]) == "number",
          "Invalid type to argument " ..
          argument_index .. ". Expected number, got " .. type(colour[1]) .. " in\n" .. last)
        assert(type(colour[2]) == "number",
          "Invalid type to argument " ..
          argument_index .. ". Expected number, got " .. type(colour[2]) .. " in\n" .. last)
        assert(type(colour[3]) == "number",
          "Invalid type to argument " ..
          argument_index .. ". Expected number, got " .. type(colour[3]) .. " in\n" .. last)
        assert(colour[1] >= 0 and colour[1] <= 255,
          "Invalid value to argument " ..
          argument_index .. ". Expected number between 0 and 255, got " .. colour[1] .. " in\n" .. last)
        assert(colour[2] >= 0 and colour[2] <= 255,
          "Invalid value to argument " ..
          argument_index .. ". Expected number between 0 and 255, got " .. colour[2] .. " in\n" .. last)
        assert(colour[3] >= 0 and colour[3] <= 255,
          "Invalid value to argument " ..
          argument_index .. ". Expected number between 0 and 255, got " .. colour[3] .. " in\n" .. last)
      end,
      hsl_table = function(hsl, argument_index, nil_allowed)
        if nil_allowed and hsl == nil then return end

        local last = ___.v.get_last_traceback_line()

        ___.v.type(hsl, "table", argument_index, nil_allowed)
        assert(#hsl == 3, "Invalid number of elements to argument " .. argument_index ..
          ". Expected 3, got " .. #hsl .. " in\n" .. last)

        assert(type(hsl[1]) == "number",
          "Invalid type to argument " .. argument_index ..
          ". Expected number for hue, got " .. type(hsl[1]) .. " in\n" .. last)
        assert(type(hsl[2]) == "number",
          "Invalid type to argument " .. argument_index ..
          ". Expected number for saturation, got " .. type(hsl[2]) .. " in\n" .. last)
        assert(type(hsl[3]) == "number",
          "Invalid type to argument " .. argument_index ..
          ". Expected number for lightness, got " .. type(hsl[3]) .. " in\n" .. last)

        assert(hsl[1] >= 0 and hsl[1] <= 360,
          "Invalid value to argument " .. argument_index ..
          ". Expected hue between 0 and 360, got " .. hsl[1] .. " in\n" .. last)
        assert(hsl[2] >= 0 and hsl[2] <= 100,
          "Invalid value to argument " .. argument_index ..
          ". Expected saturation between 0 and 100, got " .. hsl[2] .. " in\n" .. last)
        assert(hsl[3] >= 0 and hsl[3] <= 100,
          "Invalid value to argument " .. argument_index ..
          ". Expected lightness between 0 and 100, got " .. hsl[3] .. " in\n" .. last)
      end,
      colour_name = function(colour, argument_index, nil_allowed)
        if nil_allowed and colour == nil then return end

        -- Extract the colour name if enclosed in <>
        local name = rex.match(colour, "<?([\\w_]+)>?") or colour

        ___.v.rgb_table(color_table[name], argument_index, nil_allowed)
      end
    }
  end
})
