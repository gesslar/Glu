describe("colour module", function()
  local g

  setup(function()
    g = Glu("Glu")
  end)

  -- ========================================================================
  -- RGB to HSL conversion
  -- ========================================================================

  describe("rgb_to_hsl", function()
    it("should convert pure red", function()
      assert.are.same({0, 100, 50}, g.colour.rgb_to_hsl({255, 0, 0}))
    end)

    it("should convert pure green", function()
      assert.are.same({120, 100, 50}, g.colour.rgb_to_hsl({0, 255, 0}))
    end)

    it("should convert pure blue", function()
      assert.are.same({240, 100, 50}, g.colour.rgb_to_hsl({0, 0, 255}))
    end)

    it("should convert white", function()
      assert.are.same({0, 0, 100}, g.colour.rgb_to_hsl({255, 255, 255}))
    end)

    it("should convert black", function()
      assert.are.same({0, 0, 0}, g.colour.rgb_to_hsl({0, 0, 0}))
    end)

    it("should convert mid gray", function()
      local hsl = g.colour.rgb_to_hsl({128, 128, 128})
      assert.are.equal(0, hsl[1])
      assert.are.equal(0, hsl[2])
      assert.are.equal(50, hsl[3])
    end)

    it("should convert a mixed colour", function()
      -- Teal-ish: {0, 128, 128} => ~{180, 100, 25}
      local hsl = g.colour.rgb_to_hsl({0, 128, 128})
      assert.are.equal(180, hsl[1])
      assert.are.equal(100, hsl[2])
      assert.are.equal(25, hsl[3])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.rgb_to_hsl("red")
      end)
    end)

    it("should error on table with wrong number of elements", function()
      assert.has_error(function()
        g.colour.rgb_to_hsl({255, 0})
      end)
    end)

    it("should error on out-of-range values", function()
      assert.has_error(function()
        g.colour.rgb_to_hsl({256, 0, 0})
      end)
    end)

    it("should error on negative values", function()
      assert.has_error(function()
        g.colour.rgb_to_hsl({-1, 0, 0})
      end)
    end)

    it("should error on non-number elements", function()
      assert.has_error(function()
        g.colour.rgb_to_hsl({"a", "b", "c"})
      end)
    end)
  end)

  -- ========================================================================
  -- HSL to RGB conversion
  -- ========================================================================

  describe("hsl_to_rgb", function()
    it("should convert pure red hsl", function()
      assert.are.same({255, 0, 0}, g.colour.hsl_to_rgb({0, 100, 50}))
    end)

    it("should convert pure green hsl", function()
      assert.are.same({0, 255, 0}, g.colour.hsl_to_rgb({120, 100, 50}))
    end)

    it("should convert pure blue hsl", function()
      assert.are.same({0, 0, 255}, g.colour.hsl_to_rgb({240, 100, 50}))
    end)

    it("should convert white hsl", function()
      assert.are.same({255, 255, 255}, g.colour.hsl_to_rgb({0, 0, 100}))
    end)

    it("should convert black hsl", function()
      assert.are.same({0, 0, 0}, g.colour.hsl_to_rgb({0, 0, 0}))
    end)

    it("should convert zero saturation to gray", function()
      local rgb = g.colour.hsl_to_rgb({180, 0, 50})
      assert.are.equal(rgb[1], rgb[2])
      assert.are.equal(rgb[2], rgb[3])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.hsl_to_rgb("blue")
      end)
    end)

    it("should error on hue out of range", function()
      assert.has_error(function()
        g.colour.hsl_to_rgb({361, 50, 50})
      end)
    end)

    it("should error on saturation out of range", function()
      assert.has_error(function()
        g.colour.hsl_to_rgb({180, 101, 50})
      end)
    end)

    it("should error on lightness out of range", function()
      assert.has_error(function()
        g.colour.hsl_to_rgb({180, 50, 101})
      end)
    end)
  end)

  -- ========================================================================
  -- Round-trip conversion
  -- ========================================================================

  describe("rgb_to_hsl / hsl_to_rgb round-trip", function()
    it("should round-trip pure red", function()
      local rgb = {255, 0, 0}
      assert.are.same(rgb, g.colour.hsl_to_rgb(g.colour.rgb_to_hsl(rgb)))
    end)

    it("should round-trip pure green", function()
      local rgb = {0, 255, 0}
      assert.are.same(rgb, g.colour.hsl_to_rgb(g.colour.rgb_to_hsl(rgb)))
    end)

    it("should round-trip pure blue", function()
      local rgb = {0, 0, 255}
      assert.are.same(rgb, g.colour.hsl_to_rgb(g.colour.rgb_to_hsl(rgb)))
    end)

    it("should round-trip white", function()
      local rgb = {255, 255, 255}
      assert.are.same(rgb, g.colour.hsl_to_rgb(g.colour.rgb_to_hsl(rgb)))
    end)

    it("should round-trip black", function()
      local rgb = {0, 0, 0}
      assert.are.same(rgb, g.colour.hsl_to_rgb(g.colour.rgb_to_hsl(rgb)))
    end)

    it("should approximately round-trip an arbitrary colour", function()
      local rgb = {100, 150, 200}
      local result = g.colour.hsl_to_rgb(g.colour.rgb_to_hsl(rgb))
      -- Allow rounding tolerance of 1
      assert.is_true(math.abs(result[1] - rgb[1]) <= 1)
      assert.is_true(math.abs(result[2] - rgb[2]) <= 1)
      assert.is_true(math.abs(result[3] - rgb[3]) <= 1)
    end)
  end)

  -- ========================================================================
  -- to_hex
  -- ========================================================================

  describe("to_hex", function()
    it("should convert white to hex", function()
      assert.are.equal("#ffffff", g.colour.to_hex({255, 255, 255}))
    end)

    it("should convert black to hex", function()
      assert.are.equal("#000000", g.colour.to_hex({0, 0, 0}))
    end)

    it("should convert pure red to hex", function()
      assert.are.equal("#ff0000", g.colour.to_hex({255, 0, 0}))
    end)

    it("should convert a mixed colour to hex", function()
      assert.are.equal("#1e3264", g.colour.to_hex({30, 50, 100}))
    end)

    it("should pad single-digit hex values with zero", function()
      assert.are.equal("#010203", g.colour.to_hex({1, 2, 3}))
    end)

    it("should work without background", function()
      assert.are.equal("#ff0000", g.colour.to_hex({255, 0, 0}, nil))
    end)

    it("should include background colour when provided", function()
      assert.are.equal("#ff0000,0000ff", g.colour.to_hex({255, 0, 0}, {0, 0, 255}))
    end)

    it("should format background with leading zeros", function()
      assert.are.equal("#ffffff,000000", g.colour.to_hex({255, 255, 255}, {0, 0, 0}))
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.to_hex("#ffffff")
      end)
    end)

    it("should error on invalid background", function()
      assert.has_error(function()
        g.colour.to_hex({255, 0, 0}, "yes")
      end)
    end)
  end)

  -- ========================================================================
  -- is_light
  -- ========================================================================

  describe("is_light", function()
    it("should return true for white", function()
      assert.is_true(g.colour.is_light({255, 255, 255}))
    end)

    it("should return false for black", function()
      assert.is_false(g.colour.is_light({0, 0, 0}))
    end)

    it("should return true for a light colour", function()
      assert.is_true(g.colour.is_light({200, 200, 200}))
    end)

    it("should return false for a dark colour", function()
      assert.is_false(g.colour.is_light({30, 30, 30}))
    end)

    it("should return true for yellow (high luminance)", function()
      assert.is_true(g.colour.is_light({255, 255, 0}))
    end)

    it("should return false for dark blue (low luminance)", function()
      assert.is_false(g.colour.is_light({0, 0, 128}))
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.is_light(255)
      end)
    end)
  end)

  -- ========================================================================
  -- adjust_colour
  -- ========================================================================

  describe("adjust_colour", function()
    it("should lighten a colour", function()
      assert.are.same({130, 130, 130}, g.colour.adjust_colour({100, 100, 100}, 30, true))
    end)

    it("should darken a colour", function()
      assert.are.same({70, 70, 70}, g.colour.adjust_colour({100, 100, 100}, 30, false))
    end)

    it("should clamp lightened values to 255", function()
      local result = g.colour.adjust_colour({240, 240, 240}, 50, true)
      assert.are.equal(255, result[1])
      assert.are.equal(255, result[2])
      assert.are.equal(255, result[3])
    end)

    it("should clamp darkened values to 0", function()
      local result = g.colour.adjust_colour({10, 10, 10}, 50, false)
      assert.are.equal(0, result[1])
      assert.are.equal(0, result[2])
      assert.are.equal(0, result[3])
    end)

    it("should default amount to 30 when nil", function()
      assert.are.same({130, 130, 130}, g.colour.adjust_colour({100, 100, 100}, nil, true))
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.adjust_colour(100, 30, true)
      end)
    end)
  end)

  -- ========================================================================
  -- lighten
  -- ========================================================================

  describe("lighten", function()
    it("should lighten a colour by specified amount", function()
      assert.are.same({150, 150, 150}, g.colour.lighten({100, 100, 100}, 50))
    end)

    it("should default to 30 when amount not specified", function()
      assert.are.same({130, 130, 130}, g.colour.lighten({100, 100, 100}))
    end)

    it("should clamp at 255", function()
      local result = g.colour.lighten({250, 250, 250}, 50)
      assert.are.equal(255, result[1])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.lighten(100, 50)
      end)
    end)
  end)

  -- ========================================================================
  -- darken
  -- ========================================================================

  describe("darken", function()
    it("should darken a colour by specified amount", function()
      assert.are.same({50, 50, 50}, g.colour.darken({100, 100, 100}, 50))
    end)

    it("should default to 30 when amount not specified", function()
      assert.are.same({70, 70, 70}, g.colour.darken({100, 100, 100}))
    end)

    it("should clamp at 0", function()
      local result = g.colour.darken({10, 10, 10}, 50)
      assert.are.equal(0, result[1])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.darken(100, 50)
      end)
    end)
  end)

  -- ========================================================================
  -- lighten_or_darken
  -- ========================================================================

  describe("lighten_or_darken", function()
    it("should darken when both colours are light", function()
      local result = g.colour.lighten_or_darken({200, 200, 200}, {220, 220, 220})
      -- Both are light, so result should be darker than original
      assert.is_true(result[1] < 200)
    end)

    it("should lighten when both colours are dark", function()
      local result = g.colour.lighten_or_darken({30, 30, 30}, {20, 20, 20})
      -- Both are dark, so result should be lighter than original
      assert.is_true(result[1] > 30)
    end)

    it("should return original when colours already contrast", function()
      local rgb = {200, 200, 200}
      local result = g.colour.lighten_or_darken(rgb, {20, 20, 20})
      assert.are.same(rgb, result)
    end)

    it("should use default amount of 85", function()
      local result = g.colour.lighten_or_darken({200, 200, 200}, {200, 200, 200})
      -- Darkened by 85: 200 - 85 = 115
      assert.are.same({115, 115, 115}, result)
    end)

    it("should use custom amount", function()
      local result = g.colour.lighten_or_darken({200, 200, 200}, {200, 200, 200}, 50)
      assert.are.same({150, 150, 150}, result)
    end)

    it("should error on non-number amount", function()
      assert.has_error(function()
        g.colour.lighten_or_darken({200, 200, 200}, {200, 200, 200}, "lots")
      end)
    end)
  end)

  -- ========================================================================
  -- complementary
  -- ========================================================================

  describe("complementary", function()
    it("should return 180-degree hue rotation", function()
      -- Red {255,0,0} => HSL {0,100,50} => complement {180,100,50} => Cyan {0,255,255}
      assert.are.same({0, 255, 255}, g.colour.complementary({255, 0, 0}))
    end)

    it("should return complement of green", function()
      -- Green => Magenta
      assert.are.same({255, 0, 255}, g.colour.complementary({0, 255, 0}))
    end)

    it("should return complement of blue", function()
      -- Blue => Yellow
      assert.are.same({255, 255, 0}, g.colour.complementary({0, 0, 255}))
    end)

    it("should return gray for gray input (no hue to rotate)", function()
      local result = g.colour.complementary({128, 128, 128})
      -- Gray has 0 saturation, so hue rotation doesn't change it
      assert.are.equal(result[1], result[2])
      assert.are.equal(result[2], result[3])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.complementary(255)
      end)
    end)
  end)

  -- ========================================================================
  -- grayscale
  -- ========================================================================

  describe("grayscale", function()
    it("should convert to grayscale using average", function()
      -- (35 + 50 + 100) / 3 = 61.67 => 62
      assert.are.same({62, 62, 62}, g.colour.grayscale({35, 50, 100}))
    end)

    it("should keep white as white", function()
      assert.are.same({255, 255, 255}, g.colour.grayscale({255, 255, 255}))
    end)

    it("should keep black as black", function()
      assert.are.same({0, 0, 0}, g.colour.grayscale({0, 0, 0}))
    end)

    it("should keep gray unchanged", function()
      assert.are.same({128, 128, 128}, g.colour.grayscale({128, 128, 128}))
    end)

    it("should produce equal R, G, B values", function()
      local result = g.colour.grayscale({255, 0, 0})
      assert.are.equal(result[1], result[2])
      assert.are.equal(result[2], result[3])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.grayscale("gray")
      end)
    end)
  end)

  -- ========================================================================
  -- adjust_saturation
  -- ========================================================================

  describe("adjust_saturation", function()
    it("should fully desaturate at factor 0", function()
      local result = g.colour.adjust_saturation({255, 0, 0}, 0)
      -- At factor 0, all channels should equal the average: (255+0+0)/3 = 85
      assert.are.equal(result[1], result[2])
      assert.are.equal(result[2], result[3])
    end)

    it("should keep colour unchanged at factor 1", function()
      local rgb = {100, 150, 200}
      local result = g.colour.adjust_saturation(rgb, 1)
      assert.are.same(rgb, result)
    end)

    it("should reduce saturation at factor 0.5", function()
      local result = g.colour.adjust_saturation({35, 50, 100}, 0.5)
      -- gray = (35+50+100)/3 = 61.67
      -- r = floor(61.67 + (35 - 61.67) * 0.5) = floor(61.67 - 13.33) = floor(48.33) = 48
      -- g = floor(61.67 + (50 - 61.67) * 0.5) = floor(61.67 - 5.83) = floor(55.83) = 55
      -- b = floor(61.67 + (100 - 61.67) * 0.5) = floor(61.67 + 19.17) = floor(80.83) = 80
      assert.are.same({48, 55, 80}, result)
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.adjust_saturation(255, 0.5)
      end)
    end)

    it("should error on non-number factor", function()
      assert.has_error(function()
        g.colour.adjust_saturation({100, 100, 100}, "half")
      end)
    end)
  end)

  -- ========================================================================
  -- random
  -- ========================================================================

  describe("random", function()
    it("should return a table with 3 elements", function()
      local result = g.colour.random()
      assert.are.equal(3, #result)
    end)

    it("should return values in 0-255 range", function()
      local result = g.colour.random()
      assert.is_true(result[1] >= 0 and result[1] <= 255)
      assert.is_true(result[2] >= 0 and result[2] <= 255)
      assert.is_true(result[3] >= 0 and result[3] <= 255)
    end)

    it("should return numbers", function()
      local result = g.colour.random()
      assert.are.equal("number", type(result[1]))
      assert.are.equal("number", type(result[2]))
      assert.are.equal("number", type(result[3]))
    end)
  end)

  -- ========================================================================
  -- random_shade
  -- ========================================================================

  describe("random_shade", function()
    it("should return a table with 3 elements", function()
      local result = g.colour.random_shade({128, 128, 128})
      assert.are.equal(3, #result)
    end)

    it("should return values within range of original", function()
      local base = {128, 128, 128}
      local range = 20
      local result = g.colour.random_shade(base, range)
      assert.is_true(result[1] >= 108 and result[1] <= 148)
      assert.is_true(result[2] >= 108 and result[2] <= 148)
      assert.is_true(result[3] >= 108 and result[3] <= 148)
    end)

    it("should clamp within 0-255 even with large range", function()
      local result = g.colour.random_shade({250, 5, 128}, 100)
      assert.is_true(result[1] >= 0 and result[1] <= 255)
      assert.is_true(result[2] >= 0 and result[2] <= 255)
      assert.is_true(result[3] >= 0 and result[3] <= 255)
    end)

    it("should default range to 50", function()
      local base = {128, 128, 128}
      local result = g.colour.random_shade(base)
      assert.is_true(result[1] >= 78 and result[1] <= 178)
      assert.is_true(result[2] >= 78 and result[2] <= 178)
      assert.is_true(result[3] >= 78 and result[3] <= 178)
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.random_shade(128, 50)
      end)
    end)
  end)

  -- ========================================================================
  -- interpolate
  -- ========================================================================

  describe("interpolate", function()
    it("should return first colour at factor 0", function()
      local result = g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 0)
      assert.are.same({255, 0, 0}, result)
    end)

    it("should return second colour at factor 100", function()
      local result = g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 100)
      assert.are.same({0, 0, 255}, result)
    end)

    it("should return a blend at factor 50", function()
      local result = g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50)
      -- Midpoint between red and blue in HSL space
      assert.are.equal(3, #result)
      assert.is_true(result[1] >= 0 and result[1] <= 255)
      assert.is_true(result[2] >= 0 and result[2] <= 255)
      assert.is_true(result[3] >= 0 and result[3] <= 255)
    end)

    it("should return the exact second colour at factor 100 for dark colours", function()
      local result = g.colour.interpolate({0, 0, 0}, {18, 22, 25}, 100)
      assert.are.same({18, 22, 25}, result)
    end)

    it("should keep the chromatic colour's hue when fading from black", function()
      for factor = 10, 90, 10 do
        local result = g.colour.interpolate({0, 0, 0}, {18, 22, 25}, factor, "linear")
        -- The target is blue-grey (b >= g >= r); no red/purple tint en route
        assert.is_true(result[3] >= result[2] and result[2] >= result[1])
      end
    end)

    it("should keep the chromatic colour's hue when fading to white", function()
      local result = g.colour.interpolate({255, 0, 0}, {255, 255, 255}, 50, "linear")
      -- Red lightened: green and blue rise together, no hue shift
      assert.is_true(result[1] > result[2])
      assert.are.equal(result[2], result[3])
    end)

    it("should use smooth interpolation by default", function()
      local smooth = g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 25)
      local linear = g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 25, "linear")
      -- Smooth and linear should produce different results at non-boundary points
      local differ = smooth[1] ~= linear[1] or smooth[2] ~= linear[2] or smooth[3] ~= linear[3]
      assert.is_true(differ)
    end)

    it("should accept linear method", function()
      assert.has_no.errors(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50, "linear")
      end)
    end)

    it("should accept smooth method", function()
      assert.has_no.errors(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50, "smooth")
      end)
    end)

    it("should accept smoother method", function()
      assert.has_no.errors(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50, "smoother")
      end)
    end)

    it("should accept ease_in method", function()
      assert.has_no.errors(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50, "ease_in")
      end)
    end)

    it("should accept ease_out method", function()
      assert.has_no.errors(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50, "ease_out")
      end)
    end)

    it("should error on invalid method", function()
      assert.has_error(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 50, "cubic")
      end)
    end)

    it("should error on factor below 0", function()
      assert.has_error(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, -1)
      end)
    end)

    it("should error on factor above 100", function()
      assert.has_error(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, 101)
      end)
    end)

    it("should error on non-number factor", function()
      assert.has_error(function()
        g.colour.interpolate({255, 0, 0}, {0, 0, 255}, "half")
      end)
    end)

    it("should error on invalid first colour", function()
      assert.has_error(function()
        g.colour.interpolate("red", {0, 0, 255}, 50)
      end)
    end)

    it("should error on invalid second colour", function()
      assert.has_error(function()
        g.colour.interpolate({255, 0, 0}, "blue", 50)
      end)
    end)

    it("should interpolate identical colours to approximately themselves", function()
      local result = g.colour.interpolate({100, 100, 100}, {100, 100, 100}, 50)
      -- Allow rounding tolerance from HSL round-trip
      assert.is_true(math.abs(result[1] - 100) <= 1)
      assert.is_true(math.abs(result[2] - 100) <= 1)
      assert.is_true(math.abs(result[3] - 100) <= 1)
    end)
  end)

  -- ========================================================================
  -- triad
  -- ========================================================================

  describe("triad", function()
    it("should return 2 colours", function()
      local result = g.colour.triad({255, 0, 0})
      assert.are.equal(2, #result)
    end)

    it("should return valid RGB tables", function()
      local result = g.colour.triad({255, 0, 0})
      assert.are.equal(3, #result[1])
      assert.are.equal(3, #result[2])
    end)

    it("should return 120-degree and 240-degree rotations for red", function()
      -- Red {0,100,50} + 120 = Green {120,100,50} => {0,255,0}
      -- Red {0,100,50} + 240 = Blue {240,100,50} => {0,0,255}
      local result = g.colour.triad({255, 0, 0})
      assert.are.same({0, 255, 0}, result[1])
      assert.are.same({0, 0, 255}, result[2])
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.triad(255)
      end)
    end)
  end)

  -- ========================================================================
  -- tetrad
  -- ========================================================================

  describe("tetrad", function()
    it("should return 4 colours", function()
      local result = g.colour.tetrad({255, 0, 0})
      assert.are.equal(4, #result)
    end)

    it("should include the original colour as first element", function()
      local rgb = {255, 0, 0}
      local result = g.colour.tetrad(rgb)
      assert.are.same(rgb, result[1])
    end)

    it("should return 90-degree rotations for red", function()
      local result = g.colour.tetrad({255, 0, 0})
      -- 0 + 90 = 90 degrees, 0 + 180 = cyan, 0 + 270 = 270 degrees
      assert.are.same({255, 0, 0}, result[1])
      assert.are.same({0, 255, 255}, result[3]) -- 180 degrees is complement
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.tetrad("red")
      end)
    end)
  end)

  -- ========================================================================
  -- analogous
  -- ========================================================================

  describe("analogous", function()
    it("should return 3 colours", function()
      local result = g.colour.analogous({255, 0, 0})
      assert.are.equal(3, #result)
    end)

    it("should include original colour in the middle", function()
      local rgb = {255, 0, 0}
      local result = g.colour.analogous(rgb)
      assert.are.same(rgb, result[2])
    end)

    it("should default to 30-degree separation", function()
      -- Red at hue 0: analogous at -30 (330) and +30
      local result = g.colour.analogous({255, 0, 0})
      assert.are.equal(3, #result)
      -- All should be valid RGB tables
      assert.are.equal(3, #result[1])
      assert.are.equal(3, #result[3])
    end)

    it("should accept custom angle", function()
      local result_30 = g.colour.analogous({255, 0, 0}, 30)
      local result_60 = g.colour.analogous({255, 0, 0}, 60)
      -- Different angles should produce different colours
      local differ = result_30[1][1] ~= result_60[1][1] or
          result_30[1][2] ~= result_60[1][2] or
          result_30[1][3] ~= result_60[1][3]
      assert.is_true(differ)
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.analogous("red")
      end)
    end)

    it("should error on non-number angle", function()
      assert.has_error(function()
        g.colour.analogous({255, 0, 0}, "wide")
      end)
    end)
  end)

  -- ========================================================================
  -- split_complement
  -- ========================================================================

  describe("split_complement", function()
    it("should return 2 colours", function()
      local result = g.colour.split_complement({255, 0, 0})
      assert.are.equal(2, #result)
    end)

    it("should return valid RGB tables", function()
      local result = g.colour.split_complement({255, 0, 0})
      assert.are.equal(3, #result[1])
      assert.are.equal(3, #result[2])
    end)

    it("should return colours near the complement", function()
      -- Red complement is cyan (hue 180). Split at default 30:
      -- 180 - 30 = 150 and 180 + 30 = 210
      local result = g.colour.split_complement({255, 0, 0})
      -- Both should be in the blue-green range, not red
      -- Just verify they're valid and different from each other
      local differ = result[1][1] ~= result[2][1] or
          result[1][2] ~= result[2][2] or
          result[1][3] ~= result[2][3]
      assert.is_true(differ)
    end)

    it("should accept custom angle", function()
      local result_30 = g.colour.split_complement({255, 0, 0}, 30)
      local result_10 = g.colour.split_complement({255, 0, 0}, 10)
      -- Different angles produce different splits
      local differ = result_30[1][1] ~= result_10[1][1] or
          result_30[1][2] ~= result_10[1][2] or
          result_30[1][3] ~= result_10[1][3]
      assert.is_true(differ)
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.split_complement("red")
      end)
    end)

    it("should error on non-number angle", function()
      assert.has_error(function()
        g.colour.split_complement({255, 0, 0}, "narrow")
      end)
    end)
  end)

  -- ========================================================================
  -- monochrome
  -- ========================================================================

  describe("monochrome", function()
    it("should default to 5 steps", function()
      local result = g.colour.monochrome({255, 0, 0})
      assert.are.equal(5, #result)
    end)

    it("should return requested number of steps", function()
      local result = g.colour.monochrome({255, 0, 0}, 3)
      assert.are.equal(3, #result)
    end)

    it("should return valid RGB tables", function()
      local result = g.colour.monochrome({100, 150, 200}, 4)
      for i = 1, #result do
        assert.are.equal(3, #result[i])
        assert.is_true(result[i][1] >= 0 and result[i][1] <= 255)
        assert.is_true(result[i][2] >= 0 and result[i][2] <= 255)
        assert.is_true(result[i][3] >= 0 and result[i][3] <= 255)
      end
    end)

    it("should produce variations of the same hue", function()
      local result = g.colour.monochrome({255, 0, 0}, 3)
      -- All results should share the same hue (red = 0 or 360)
      for i = 1, #result do
        local hsl = g.colour.rgb_to_hsl(result[i])
        -- Hue should be 0 (red) unless saturation is 0
        if hsl[2] > 0 then
          assert.are.equal(0, hsl[1])
        end
      end
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.monochrome("red", 5)
      end)
    end)

    it("should error on non-number steps", function()
      assert.has_error(function()
        g.colour.monochrome({255, 0, 0}, "many")
      end)
    end)
  end)

  -- ========================================================================
  -- contrast_ratio
  -- ========================================================================

  describe("contrast_ratio", function()
    it("should return 21 for black vs white", function()
      local ratio = g.colour.contrast_ratio({0, 0, 0}, {255, 255, 255})
      assert.are.equal(21, ratio)
    end)

    it("should return 1 for identical colours", function()
      local ratio = g.colour.contrast_ratio({128, 128, 128}, {128, 128, 128})
      assert.are.equal(1, ratio)
    end)

    it("should be symmetric (order should not matter)", function()
      local ratio1 = g.colour.contrast_ratio({255, 0, 0}, {0, 0, 255})
      local ratio2 = g.colour.contrast_ratio({0, 0, 255}, {255, 0, 0})
      assert.are.equal(ratio1, ratio2)
    end)

    it("should return a ratio >= 1", function()
      local ratio = g.colour.contrast_ratio({100, 100, 100}, {150, 150, 150})
      assert.is_true(ratio >= 1)
    end)

    it("should error on non-table first argument", function()
      assert.has_error(function()
        g.colour.contrast_ratio("white", {0, 0, 0})
      end)
    end)

    it("should error on non-table second argument", function()
      assert.has_error(function()
        g.colour.contrast_ratio({255, 255, 255}, "black")
      end)
    end)
  end)

  -- ========================================================================
  -- contrast
  -- ========================================================================

  describe("contrast", function()
    it("should invert lightness of a light colour", function()
      local result = g.colour.contrast({255, 255, 255})
      -- White HSL {0,0,100} => inverted lightness {0,0,0} => Black
      assert.are.same({0, 0, 0}, result)
    end)

    it("should invert lightness of a dark colour", function()
      local result = g.colour.contrast({0, 0, 0})
      -- Black HSL {0,0,0} => inverted lightness {0,0,100} => White
      assert.are.same({255, 255, 255}, result)
    end)

    it("should preserve hue and saturation", function()
      -- Red {255,0,0} HSL {0,100,50} => inverted {0,100,50} (50 stays at 50!)
      -- Actually 100-50=50, so same lightness for pure colours
      local rgb = {255, 0, 0}
      local result = g.colour.contrast(rgb)
      local original_hsl = g.colour.rgb_to_hsl(rgb)
      local result_hsl = g.colour.rgb_to_hsl(result)
      assert.are.equal(original_hsl[1], result_hsl[1]) -- same hue
      assert.are.equal(original_hsl[2], result_hsl[2]) -- same saturation
      assert.are.equal(100 - original_hsl[3], result_hsl[3]) -- inverted lightness
    end)

    it("should error on non-table input", function()
      assert.has_error(function()
        g.colour.contrast(255)
      end)
    end)
  end)

  -- ========================================================================
  -- Validators
  -- ========================================================================

  describe("validators", function()
    describe("rgb_table", function()
      it("should accept valid RGB table", function()
        assert.has_no.errors(function()
          g.colour.rgb_to_hsl({128, 128, 128})
        end)
      end)

      it("should reject nil when not allowed", function()
        assert.has_error(function()
          g.colour.rgb_to_hsl(nil)
        end)
      end)

      it("should reject empty table", function()
        assert.has_error(function()
          g.colour.rgb_to_hsl({})
        end)
      end)

      it("should reject table with too few elements", function()
        assert.has_error(function()
          g.colour.rgb_to_hsl({255, 0})
        end)
      end)

      it("should reject table with non-number elements", function()
        assert.has_error(function()
          g.colour.rgb_to_hsl({255, "green", 0})
        end)
      end)

      it("should reject values above 255", function()
        assert.has_error(function()
          g.colour.rgb_to_hsl({300, 0, 0})
        end)
      end)

      it("should reject negative values", function()
        assert.has_error(function()
          g.colour.rgb_to_hsl({-10, 0, 0})
        end)
      end)

      it("should accept boundary values 0 and 255", function()
        assert.has_no.errors(function()
          g.colour.rgb_to_hsl({0, 0, 0})
          g.colour.rgb_to_hsl({255, 255, 255})
        end)
      end)
    end)

    describe("hsl_table", function()
      it("should accept valid HSL table", function()
        assert.has_no.errors(function()
          g.colour.hsl_to_rgb({180, 50, 50})
        end)
      end)

      it("should reject nil when not allowed", function()
        assert.has_error(function()
          g.colour.hsl_to_rgb(nil)
        end)
      end)

      it("should reject empty table", function()
        assert.has_error(function()
          g.colour.hsl_to_rgb({})
        end)
      end)

      it("should reject hue above 360", function()
        assert.has_error(function()
          g.colour.hsl_to_rgb({400, 50, 50})
        end)
      end)

      it("should reject saturation above 100", function()
        assert.has_error(function()
          g.colour.hsl_to_rgb({180, 150, 50})
        end)
      end)

      it("should reject lightness above 100", function()
        assert.has_error(function()
          g.colour.hsl_to_rgb({180, 50, 150})
        end)
      end)

      it("should reject negative hue", function()
        assert.has_error(function()
          g.colour.hsl_to_rgb({-10, 50, 50})
        end)
      end)

      it("should accept boundary values", function()
        assert.has_no.errors(function()
          g.colour.hsl_to_rgb({0, 0, 0})
          g.colour.hsl_to_rgb({360, 100, 100})
        end)
      end)
    end)
  end)
end)
