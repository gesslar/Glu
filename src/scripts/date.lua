local DateClass = Glu.glass.register({
  class_name = "DateClass",
  name = "date",
  dependencies = {},
  setup = function(___, self, opts)
    local v = ___.v

    -- Calendar approximations used when formatting long durations.
    local DAYS_PER_YEAR = 365
    local DAYS_PER_MONTH = 30

    --- Converts a number of seconds into hours, minutes, and seconds.
    --- When `as_string` is true, returns a single human-readable string such as
    --- "1y 2mo 3d 4h 5m 6s", omitting any zero units ("0s" when all are zero).
    --- A year is 365 days and a month is 30 days. Otherwise, returns three
    --- zero-padded "HH", "MM", "SS" strings, where hours are not capped at 24.
    ---
    ---@param seconds number The number of seconds to convert.
    ---@param as_string boolean|nil Whether to return a single formatted string instead of three values. (Optional. Default is false.)
    ---@return string hours The zero-padded hours, or the single formatted string when `as_string` is true.
    ---@return string minutes The zero-padded minutes. Not returned when `as_string` is true.
    ---@return string seconds The zero-padded seconds. Not returned when `as_string` is true.
    ---@example
    --- ```lua
    --- date.shms(3661)
    --- -- "01", "01", "01"
    --- date.shms(3661, true)
    --- -- "1h 1m 1s"
    --- date.shms(90061, true)
    --- -- "1d 1h 1m 1s"
    --- ```
    function self.shms(seconds, as_string)
      v.type(seconds, "number", 1, false)
      v.type(as_string, "boolean", 2, true)

      local s = seconds or 0

      -- Handle negative seconds
      local is_negative = s < 0
      s = math.abs(s)

      -- Hours
      local hh = math.floor(s / (60 * 60))
      -- Minutes
      local mm = math.floor((s % (60 * 60)) / 60)
      -- Seconds
      local ss = s % 60

      if is_negative then
        -- Adjust for negative seconds
        if ss > 0 then
          ss = 60 - ss
          mm = mm + 1
        end

        if mm > 0 then
          mm = 60 - mm
          hh = (hh == 0) and 23 or (hh - 1)
        else
          hh = (hh == 0) and 23 or (hh - 1)
        end
      end

      if as_string then
        -- Break the hours down further into years, months, and days.
        local dd = math.floor(hh / 24)
        local hours = hh % 24
        local yy = math.floor(dd / DAYS_PER_YEAR)
        dd = dd % DAYS_PER_YEAR
        local mo = math.floor(dd / DAYS_PER_MONTH)
        dd = dd % DAYS_PER_MONTH

        local r = {}
        if yy ~= 0 then
          r[#r + 1] = yy .. "y"
        end
        if mo ~= 0 then
          r[#r + 1] = mo .. "mo"
        end
        if dd ~= 0 then
          r[#r + 1] = dd .. "d"
        end
        if hours ~= 0 then
          r[#r + 1] = hours .. "h"
        end
        if mm ~= 0 then
          r[#r + 1] = mm .. "m"
        end
        if ss ~= 0 then
          r[#r + 1] = ss .. "s"
        end

        if #r == 0 then
          return "0s"
        end

        return table.concat(r, " ")
      else
        local result_hours = string.format("%02d", hh)
        local result_minutes = string.format("%02d", mm)
        local result_seconds = string.format("%02d", ss)
        return result_hours, result_minutes, result_seconds
      end
    end
  end
})
