local StringClass = Glu.glass.register({
  name = "string",
  class_name = "StringClass",
  dependencies = { "table" },
  setup = function(___, self)
    --- Capitalizes the first character of a string.
    ---
    ---@param str string The string to capitalize.
    ---@return string result The capitalized string.
    ---@example
    --- ```lua
    --- string.capitalize("hello")
    --- -- "Hello"
    --- ```
    function self.capitalize(str)
      ___.v.type(str, "string", 1, false)
      assert(str ~= "", "Expected a non-empty string")

      local result = str:gsub("^%l", string.upper)
      return result or str
    end

    --- Trims whitespace from the beginning and end of a string.
    ---
    ---@param str string The string to trim.
    ---@return string trimmed The trimmed string.
    ---@example
    --- ```lua
    --- string.trim("  hello  ")
    --- -- "hello"
    --- ```
    function self.trim(str)
      ___.v.type(str, "string", 1, false)
      return str:match("^%s*(.-)%s*$")
    end

    --- Trims whitespace from the left side of a string.
    ---
    ---@param str string The string to trim.
    ---@return string trimmed The trimmed string.
    ---@example
    --- ```lua
    --- string.ltrim("  hello  ")
    --- -- "hello  "
    --- ```
    function self.ltrim(str)
      ___.v.type(str, "string", 1, false)
      return str:match("^%s*(.-)$")
    end

    --- Trims whitespace from the right side of a string.
    ---
    ---@param str string The string to trim.
    ---@return string trimmed The trimmed string.
    ---@example
    --- ```lua
    --- string.rtrim("  hello  ")
    --- -- "  hello"
    --- ```
    function self.rtrim(str)
      ___.v.type(str, "string", 1, false)
      return str:match("^(.-)%s*$")
    end

    --- Strips line breaks from a string.
    ---
    ---@param str string The string to strip line breaks from.
    ---@return string result The string with line breaks removed.
    ---@example
    --- ```lua
    --- string.strip_linebreaks("hello\nworld")
    --- -- "helloworld"
    --- ```
    function self.strip_linebreaks(str)
      ___.v.type(str, "string", 1, false)
      local result = str:gsub("[\r\n]", "")
      return result or str
    end

    --- Replaces all occurrences of a pattern in a string.
    ---
    ---@param str string The string to replace occurrences in.
    ---@param pattern string The pattern to replace.
    ---@param replacement string The replacement string.
    ---@return string str The string with occurrences replaced.
    ---@example
    --- ```lua
    --- string.replace("hello world", "o", "a")
    --- -- "hella warld"
    --- ```
    function self.replace(str, pattern, replacement)
      ___.v.type(str, "string", 1, false)
      ___.v.type(pattern, "string", 2, false)
      ___.v.type(replacement, "string", 3, false)

      while string.find(str, pattern) do
        str = string.gsub(str, pattern, replacement) or str
      end

      return str
    end

    --- Splits a string into a table of strings using PCRE regex. If no
    --- delimiter is provided, it defaults to ".", which will split the string
    --- into individual characters.
    ---
    ---@param str string The string to split.
    ---@param delimiter string The regex delimiter to split the string by.
    ---@return table parts The split string.
    ---@example
    --- ```lua
    --- string.split("hello world")
    --- -- {"h", "e", "l", "l", "o", " ", "w", "o", "r", "l", "d"}
    ---
    --- string.split("hello world", " ")
    --- -- {"hello", "world"}
    ---
    --- string.split("hello.world", "\\.")
    --- -- {"hello", "world"}
    ---
    --- string.split("hello world", "o")
    --- -- {"hell", " w", "rld"}
    --- ```
    function self.split(str, delimiter)
      ___.v.type(str, "string", 1, false)
      ___.v.type(delimiter, "string", 2, true)

      local t = {}
      delimiter = delimiter or "."

      for part in str:gmatch("[^" .. delimiter .. "]+") do
        table.insert(t, part)
      end

      return t
    end

    --- Walks over a string or table, splitting the string with a PCRE regex
    --- delimiter and returning an iterator.
    ---
    ---@param input string The string to walk over.
    ---@param delimiter string The regex delimiter to split the string by.
    ---@return function iterator The iterator function.
    ---@example
    --- ```lua
    --- for i, part in string.walk("hello world") do
    ---   print(i, part) -- prints 1=h, 2=e, 3=l, 4=l, 5=o, 6= , 7=w, 8=o, 9=r, 10=l, 11=d
    --- end
    --- ```
    function self.walk(input, delimiter)
      ___.v.type(input, "string", 1, false)
      ___.v.type(delimiter, "string", 2, true)

      local data
      if type(input) == "string" then
        data = self.split(input, delimiter)
      else
        data = input
      end

      return ___.table.walk(data)
    end

    --- Formats a number with thousands separators and decimal places.
    --- If not specified, defaults to "," for thousands and "." for decimal.
    ---
    ---@example
    --- ```lua
    --- string.format_number(1234567.89)
    --- -- "1,234,567.89"
    --- ```
    ---@param number string|number The number to format (number or string)
    ---@param thousands string The thousands separator (optional, defaults to ",")
    ---@param decimal string The decimal separator (optional, defaults to ".")
    ---@return string formatted The formatted number
    function self.format_number(number, thousands, decimal)
      ___.v.type(number, "number|string", 1, false)
      ___.v.type(thousands, "string", 2, true)
      ___.v.type(decimal, "string", 3, true)

      -- Set defaults
      thousands = thousands or ","
      decimal = decimal or "."

      number = tonumber(number) or 0
      local is_negative = number < 0
      number = math.abs(number)

      -- Convert to string if needed
      local numStr = tostring(number)

      -- Split integer and decimal parts
      local intPart, decPart = numStr:match("([^%.]*)%.?(.*)")

      -- Add thousands separators to integer part
      local formatted = ""
      local length = #intPart

      for i = 1, length do
        if i > 1 and (i - 1) % 3 == 0 then
          formatted = thousands .. formatted
        end
        formatted = intPart:sub(length - i + 1, length - i + 1) .. formatted
      end

      -- Add decimal part if it exists
      if decPart and decPart ~= "" then
        formatted = formatted .. decimal .. decPart
      end

      -- Restore negative sign if needed
      if is_negative then formatted = "-" .. formatted end

      return formatted
    end

    --- Parses a formatted number string back to a number.
    ---
    ---@param str string The formatted number string.
    ---@param thousands string The thousands separator (optional, defaults to ",").
    ---@param decimal string The decimal separator (optional, defaults to ".").
    ---@return number number The parsed number.
    ---@example
    --- ```lua
    --- string.parse_formatted_number("1,234,567.89")
    --- -- 1234567.89
    --- ```
    function self.parse_formatted_number(str, thousands, decimal)
      ___.v.type(str, "string", 1, false)
      ___.v.type(thousands, "string", 2, true)
      ___.v.type(decimal, "string", 3, true)

      thousands = thousands or ","
      decimal = decimal or "."

      -- Remove thousands separators (escape for pattern matching)
      str = str:gsub(thousands:gsub("([%.%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"), "") or str

      -- Convert decimal separator to period if different
      if decimal ~= "." then
        str = str:gsub(decimal:gsub("([%.%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"), ".") or str
      end

      -- Convert to number
      return tonumber(str) or 0
    end

    --- Checks if a string starts with a given PCRE regex pattern.
    --- If the pattern does not start with "^", it is prepended with "^".
    ---
    ---@param str string The string to check.
    ---@param start string The pattern to check for.
    ---@return boolean matched Whether the string starts with the pattern.
    ---@example
    --- ```lua
    --- string.starts_with("hello world", "hello")
    --- -- true
    --- ```
    function self.starts_with(str, start)
      ___.v.type(str, "string", 1, false)
      ___.v.type(start, "string", 2, false)

      start = string.sub(start, 1) == "^" and start or "^" .. start

      return rex.match(str, start) ~= nil
    end

    --- Checks if a string ends with a given PCRE regex pattern.
    --- If the pattern does not end with "$", it is appended with "$".
    ---
    ---@param str string The string to check.
    ---@param ending string The pattern to check for.
    ---@return boolean matched Whether the string ends with the pattern.
    ---@example
    --- ```lua
    --- string.ends_with("hello world", "world")
    --- -- true
    --- ```
    function self.ends_with(str, ending)
      ___.v.type(str, "string", 1, false)
      ___.v.type(ending, "string", 2, false)

      ending = string.sub(ending, 1) == "$" and ending or ending .. "$"

      return rex.match(str, ending) ~= nil
    end

    --- Checks if a string contains a given PCRE regex pattern. The pattern
    --- may not start with "^" or end with "$". For those, use
    --- `string.starts_with` and `string.ends_with`.
    ---
    ---@param str string The string to check.
    ---@param pattern string The pattern to check for.
    ---@return boolean matched Whether the string contains the pattern.
    ---@example
    --- ```lua
    --- string.contains("hello world", "world")
    --- -- true
    --- ```
    function self.contains(str, pattern)
      ___.v.type(str, "string", 1, false)
      ___.v.type(pattern, "string", 2, false)
      ___.v.test(string.sub(pattern, 1, 1) ~= "^", "Expected pattern to not start with ^", 2)
      ___.v.test(string.sub(pattern, -1) ~= "$", "Expected pattern to not end with $", 2)

      return rex.match(str, pattern) ~= nil
    end

    --- Appends a suffix to a string if it does not already end with the suffix.
    ---
    ---@param str string The string to append to.
    ---@param suffix string The suffix to append.
    ---@return string result The string with the suffix appended.
    ---@example
    --- ```lua
    --- string.append("hello", " world")
    --- -- "hello world"
    --- ```
    function self.append(str, suffix)
      ___.v.type(str, "string", 1, false)
      ___.v.type(suffix, "string", 2, false)

      return self.ends_with(str, suffix) and str or str .. suffix
    end

    --- Prepends a prefix to a string if it does not already start with the prefix.
    ---
    ---@param str string The string to prepend to.
    ---@param prefix string The prefix to prepend.
    ---@return string result The string with the prefix prepended.
    ---@example
    --- ```lua
    --- string.prepend("world", "hello ")
    --- -- "hello world"
    --- ```
    function self.prepend(str, prefix)
      ___.v.type(str, "string", 1, false)
      ___.v.type(prefix, "string", 2, false)

      return self.starts_with(str, prefix) and str or prefix .. str
    end

    --- Implementation of reg_assoc for Mudlet using rex PCRE support
    ---@param text string The text to search through
    ---@param patterns table The patterns to search for
    ---@param tokens table The tokens to replace the patterns with
    ---@param default_token string The default token to use if no pattern is found (optional, defaults to "")
    ---@return table results A table of match results.
    ---@return table token_list The list of replacement tokens.
    ---@example
    --- ```lua
    --- string.reg_assoc("hello world", {"hello", "world"}, {"foo", "bar"})
    --- -- {"foo", "bar"}
    --- ```
    function self.reg_assoc(text, patterns, tokens, default_token)
      ___.v.type(text, "string", 1, false)
      ___.v.type(patterns, "table", 2, false)
      ___.v.type(tokens, "table", 3, false)

      default_token = default_token or -1
      local work = text
      local results = {}
      local token_list = {}

      while #work > 0 do
        local nearest_from, nearest_to, nearest_token = nil, nil, nil

        for i, pattern in ipairs(patterns) do
          local from, to = rex.find(work, pattern)
          if from and to then
            if not nearest_from or from < nearest_from then
              nearest_from = from
              nearest_to = to
              nearest_token = tokens[i] or default_token
            end
          end
        end

        if nearest_from then
          -- Add pre-match text (if any) with default token
          if nearest_from > 1 then
            table.insert(results, work:sub(1, nearest_from - 1))
            table.insert(token_list, default_token)
          end

          -- Add the match with its associated token
          table.insert(results, work:sub(nearest_from, nearest_to))
          table.insert(token_list, nearest_token)

          -- Continue with remaining text
          work = work:sub(nearest_to + 1)
        else
          -- No match found — remaining text gets default token
          table.insert(results, work)
          table.insert(token_list, default_token)
          break
        end
      end

      return results, token_list
    end

    --- Determines whether a single character is an alphabetic letter.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_alpha True if the character is a letter (a-z, A-Z).
    ---@example
    --- ```lua
    --- string.is_alpha("a")
    --- -- true
    --- ```
    function self.is_alpha(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^[a-zA-Z]$") ~= nil
    end

    --- Determines whether a single character is a numeric digit.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_numeric True if the character is a digit (0-9).
    ---@example
    --- ```lua
    --- string.is_numeric("5")
    --- -- true
    --- ```
    function self.is_numeric(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^[0-9]$") ~= nil
    end

    --- Determines whether a single character is alphanumeric.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_alphanumeric True if the character is a letter or digit (a-z, A-Z, 0-9).
    ---@example
    --- ```lua
    --- string.is_alphanumeric("a")
    --- -- true
    --- ```
    function self.is_alphanumeric(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^[a-zA-Z0-9]$") ~= nil
    end

    --- Determines whether a single character is a whitespace character.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_whitespace True if the character is whitespace.
    ---@example
    --- ```lua
    --- string.is_whitespace(" ")
    --- -- true
    --- ```
    function self.is_whitespace(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^\\s$") ~= nil
    end

    --- Determines whether a single character is a punctuation character, meaning
    --- it is neither alphanumeric nor whitespace.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_punctuation True if the character is punctuation.
    ---@example
    --- ```lua
    --- string.is_punctuation("!")
    --- -- true
    --- ```
    function self.is_punctuation(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^[^a-zA-Z0-9\\s]$") ~= nil
    end

    --- Determines whether a single character is an uppercase letter.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_uppercase True if the character is an uppercase letter (A-Z).
    ---@example
    --- ```lua
    --- string.is_uppercase("A")
    --- -- true
    --- ```
    function self.is_uppercase(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^[A-Z]$") ~= nil
    end

    --- Determines whether a single character is a lowercase letter.
    ---
    ---@param char string The single character to test.
    ---@return boolean is_lowercase True if the character is a lowercase letter (a-z).
    ---@example
    --- ```lua
    --- string.is_lowercase("a")
    --- -- true
    --- ```
    function self.is_lowercase(char)
      ___.v.type(char, "string", 1, false)
      ___.v.test(#char == 1, "Expected a single character", 1)

      return rex.match(char, "^[a-z]$") ~= nil
    end

    --- Splits a string into a table of alternating text and numeric chunks, where
    --- consecutive digits are grouped together and converted to numbers.
    ---
    ---@param str string The string to split.
    ---@return table result A table of string and number chunks in their original order.
    ---@example
    --- ```lua
    --- string.split_natural("file42name")
    --- -- { "file", 42, "name" }
    --- ```
    function self.split_natural(str)
      ___.v.type(str, "string", 1, false)

      local result = {}
      local current = {}
      local curr_is_num = false

      for i = 1, #str do
        local c = str:sub(i, i)
        local new_is_num = self.is_numeric(c)

        if i > 1 and new_is_num ~= curr_is_num then
          local chunk = table.concat(current)
          if curr_is_num then
            table.insert(result, tonumber(chunk))
          else
            table.insert(result, chunk)
          end
          current = {}
        end

        table.insert(current, c)
        curr_is_num = new_is_num
      end

      if #current > 0 then
        local chunk = table.concat(current)
        if curr_is_num then
          table.insert(result, tonumber(chunk))
        else
          table.insert(result, chunk)
        end
      end

      return result
    end

    --- Compares two strings using natural sort order, treating embedded numbers
    --- as numeric values rather than character sequences.
    ---
    ---@param a string The first string to compare.
    ---@param b string The second string to compare.
    ---@return boolean is_before True if `a` sorts before `b` in natural order.
    ---@example
    --- ```lua
    --- string.natural_compare("item2", "item10")
    --- -- true
    --- ```
    function self.natural_compare(a, b)
      local a_parts = self.split_natural(a)
      local b_parts = self.split_natural(b)

      local len = math.min(#a_parts, #b_parts)

      for i = 1, len do
        local a_part, b_part = a_parts[i], b_parts[i]
        local a_type, b_type = type(a_part), type(b_part)

        if a_type == "number" and b_type == "number" then
          if a_part ~= b_part then
            return a_part < b_part
          end
        elseif a_type == "string" and b_type == "string" then
          if a_part ~= b_part then
            return a_part < b_part
          end
        else
          local str_a, str_b = tostring(a_part), tostring(b_part)

          if str_a ~= str_b then
            return str_a < str_b
          end
        end
      end

      return #a_parts < #b_parts
    end

    --- Finds the position of the first match of a pattern within a string.
    ---
    ---@param str string The string to search within.
    ---@param pattern string The pattern to search for.
    ---@return number|nil index The starting index of the first match, or nil if not found.
    ---@example
    --- ```lua
    --- string.index_of("hello world", "world")
    --- -- 7
    --- ```
    function self.index_of(str, pattern)
      ___.v.type(str, "string", 1, false)
      ___.v.type(pattern, "string", 2, false)

      return rex.find(str, pattern)
    end
  end
})

-- { "this", " ", "is", " ", "a", " ", "test" }
-- { 1, nil, 1, nil, 1, nil, 1 }

-- this is a thing that is num3rically unsoundh4444, and my favourite number is forty2
