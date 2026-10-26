local RegexClass = Glu.glass.register({
  name = "regex",
  class_name = "RegexClass",
  dependencies = {},
  setup = function(___, self)
    self.http_url = "^(https?:\\/\\/)((([A-Za-z0-9-]+\\.)+[A-Za-z]{2,})|localhost)(:\\d+)?(\\/[^\\s]*)?$"
  end,
  valid = function(___)
    return {
      regex = function(value, pattern, argument_index, nil_allowed)
        if nil_allowed and value == nil then
          return
        end

        local last = ___.get_last_traceback_line()

        assert(rex.match(value, pattern), "Invalid value to argument " ..
          argument_index .. ". Expected " .. pattern .. ", got " .. value ..
          " in\n" .. last)
      end
    }
  end
})
