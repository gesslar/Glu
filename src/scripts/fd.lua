local FdClass = Glu.glass.register({
  class_name = "FdClass",
  name = "fd",
  dependencies = { "table" },
  setup = function(___, self)
    --- Splits a path into a directory and file.
    ---
    --- If the directory is required and does not exist, nil is returned.
    ---
    ---@example
    --- ```lua
    --- fd.dir_file("path/to/file.txt")
    --- -- "path/to", "file.txt"
    --- ```
    ---
    ---@param path string The path to split.
    ---@param dir_required boolean Whether the directory is required (Optional. Default is false).
    ---@return string|nil dir The directory portion, or nil if the path is invalid.
    ---@return string|nil file The file portion, or nil if the path is invalid.
    function self.dir_file(path, dir_required)
      ___.v.type(path, "string", 1, false)
      ___.v.type(dir_required, "boolean", 2, true)

      dir_required = dir_required or false

      path, _ = self.fix_path(path)

      local dir, file = rex.match(path, "^(.*)/(.*)$")
      if #{ dir, file } == 2 then
        return dir, file
      end

      if dir_required and dir then
        if not self.dir_exists(dir) then
          return nil, nil
        end
      end

      return dir, file
    end

    --- Splits a path into its root, directory, and file components.
    --- The root is determined first, then the remainder is split into directory
    --- and file. If the root or directory cannot be determined, all return values
    --- are nil.
    ---
    ---@example
    --- ```lua
    --- fd.root_dir_file("c:/path/to/file.txt")
    --- -- "c:", "/path/to", "file.txt"
    --- ```
    ---
    ---@param path string The path to split.
    ---@return string|nil root The root portion, or nil if the path is invalid.
    ---@return string|nil dir The directory portion, or nil if the path is invalid.
    ---@return string|nil file The file portion, or nil if the path is invalid.
    function self.root_dir_file(path)
      ___.v.type(path, "string", 1, false)

      local root = self.determine_root(path)
      if not root then return nil, nil, nil end

      local len = utf8.len(root)
      local dir, file = self.dir_file(path:sub(len + 1))
      if not dir then return nil, nil, nil end

      return root, dir, file
    end

    --- Checks if a file exists.
    ---@param path string The path to check.
    ---@return boolean exists Whether the file exists.
    ---@example
    --- ```lua
    --- fd.file_exists("path/to/file.txt")
    --- -- true
    --- ```
    function self.file_exists(path)
      ___.v.type(path, "string", 1, false)

      local attr, message, code = lfs.attributes(path)
      if not attr then return false end

      return attr.mode == "file"
    end

    --- Checks if a directory exists.
    ---@param path string The path to check.
    ---@return boolean exists Whether the directory exists.
    ---@example
    --- ```lua
    --- fd.dir_exists("path/to/directory")
    --- -- true
    --- ```
    function self.dir_exists(path)
      ___.v.type(path, "string", 1, false)

      local attr, message, code = lfs.attributes(path)
      if not attr then return false end

      return attr.mode == "directory"
    end

    --- Reads a file.
    ---@param path string The path to the file.
    ---@param binary boolean Whether the file is binary (default false).
    ---@return string|nil data The file contents, or nil on failure.
    ---@return string|nil error The error message, if the read failed.
    ---@return number|nil code The error code, if the read failed.
    ---@example
    --- ```lua
    --- fd.read_file("path/to/file.txt")
    --- -- "contents of file"
    --- ```
    function self.read_file(path, binary)
      ___.v.type(path, "string", 1, false)
      ___.v.type(binary, "boolean", 2, true)

      local handle, error, code = io.open(path, "r" .. (binary and "b" or ""))
      if not handle then return nil, error, code end

      local data = handle:read("*a")
      handle:close()

      return data
    end

    --- Reads a file and decodes its JSON contents.
    ---
    --- The decoded value mirrors the JSON document's top-level type, so it may be
    --- a table (object or array), string, number, or boolean — not only a table.
    --- A JSON `null` decodes to the `yajl.null` sentinel (userdata), which stays
    --- distinct from the `nil` returned on failure.
    ---
    ---@param path string The path to the JSON file.
    ---@return table|string|number|boolean|userdata|nil data The decoded value, or nil if the file is missing, unreadable, or contains invalid JSON.
    ---@return string|nil error The error message: "No such file" when missing, the read error when unreadable, or the parser error when the JSON is malformed.
    ---@example
    --- ```lua
    --- fd.read_json("path/to/file.json")
    --- -- { key = "value" }
    --- ```
    function self.read_json(path)
      ___.v.type(path, "string", 1, false)

      if not self.file_exists(path) then
        return nil, "No such file '" .. path .. "'"
      end

      local data, err = self.read_file(path)

      if not data then return nil, err end

      local ok, result = pcall(yajl.to_value, data)

      if not ok then return nil, result end

      return result, nil
    end

    --- Writes to a file.
    ---@param path string The path to the file.
    ---@param data string The data to write to the file.
    ---@param overwrite boolean Whether to overwrite the file (default false).
    ---@param binary boolean Whether the file is binary (default false).
    ---@return string|table path The path to the file or nil, a table with the error and code, or the attributes of the file.
    ---@example
    --- ```lua
    --- fd.write_file("path/to/file.txt", "contents of file")
    --- -- "path/to/file.txt", "contents of file", nil
    --- ```
    function self.write_file(path, data, overwrite, binary)
      ___.v.type(path, "string", 1, false)
      ___.v.type(data, "string", 2, false)
      ___.v.type(overwrite, "boolean", 3, true)
      ___.v.type(binary, "boolean", 4, true)

      path = self.fix_path(path)

      local flag = overwrite and "w" or "a"
      local mode = binary and "b" or ""
      local handle, error, code = io.open(path, flag .. mode)
      if not handle then return nil, { error = error, code = code } end

      handle:write(data)
      handle:flush()
      handle:close()

      return path, lfs.attributes(path)
    end

    --- Fixes a path to use forward slashes.
    ---@param path string The path to fix.
    ---@return string path The fixed path.
    ---@return number num The number of replacements made.
    ---@example
    --- ```lua
    --- fd.fix_path("path\\to\\file.txt")
    --- -- "path/to/file.txt"
    --- ```
    function self.fix_path(path)
      ___.v.type(path, "string", 1, false)

      local step1, num1 = rex.gsub(path, "\\\\", "/")
      local result, num2 = rex.gsub(step1, "//", "/")
      local num = num1 + num2
      if num == 0 then return path, 0 end

      return result, num
    end

    --- Determines which path separator a path uses.
    --- Checks for a forward slash first, then a backslash, returning the first found.
    ---
    ---@param path string The path to inspect.
    ---@return string|nil sep The path separator ("/" or "\\"), or nil if none is found.
    function self.determine_path_separator(path)
      ___.v.type(path, "string", 1, false)

      for _, sep in ipairs({ "/", "\\" }) do
        if path:find(sep) then return sep end
      end

      return nil
    end

    --- Checks whether a string looks like a path by containing a path separator.
    --- This does not verify that the path exists on disk.
    ---
    ---@param path string The path string to check.
    ---@return boolean is_valid Whether the string contains a recognised path separator.
    function self.valid_path_string(path)
      ___.v.type(path, "string", 1, false)

      return self.determine_path_separator(path) ~= nil
    end

    --- Checks whether the argument is a valid path string or a table of valid path strings.
    --- The argument is first normalised to a table, then validated as either a
    --- single path string or a table of path strings.
    ---
    ---@param path string|table The path string, or table of path strings, to check.
    ---@return boolean is_valid Whether the argument is a valid path or table of paths.
    function self.valid_path_table_or_string(path)
      path = ___.table.n_cast(path)

      ___.v.indexed(path, "table", 1, false)

      if type(path) == "string" then
        return self.valid_path_string(path)
      elseif type(path) == "table" then
        return self.valid_path_table(path)
      end

      return false
    end

    --- Checks whether a path refers to an existing directory or file.
    ---
    ---@param path string The path to check.
    ---@return boolean exists Whether the path exists as a directory or a file.
    function self.valid_path(path)
      ___.v.type(path, "string", 1, false)

      return self.dir_exists(path) or self.file_exists(path)
    end

    --- Checks whether every entry in a table is a valid existing path.
    --- Each element must be a path that exists as either a directory or a file.
    ---
    ---@param paths table The uniform table of path strings to check.
    ---@return boolean is_valid Whether all paths in the table are valid existing paths.
    function self.valid_paths(paths)
      ___.v.n_uniform(paths, "string", 1, false)

      return ___.table.all(paths, self.valid_path)
    end

    --- Checks whether every entry in a table is a valid existing path.
    --- Each element must be a path that exists as either a directory or a file.
    ---
    ---@param paths table The indexed table of path strings to check.
    ---@return boolean is_valid Whether all paths in the table are valid existing paths.
    function self.valid_path_table(paths)
      ___.v.indexed(paths, "table", 1, false)

      return ___.table.all(paths, self.valid_path)
    end

    --- Ensures that a directory exists.
    ---@param path string The path to the directory.
    ---@return table|nil created A table of created directories, or nil on failure.
    ---@return string|nil err The error message, if the operation failed.
    ---@return number|nil code The error code, if the operation failed.
    ---@example
    --- ```lua
    --- fd.assure_dir("path/to/directory")
    --- ```
    function self.assure_dir(path)
      ___.v.type(path, "string", 1, false)

      local sep = self.determine_path_separator(path)

      path = self.fix_path(path)
      path = ___.string.append(path, sep)
      local root
      root, path, _ = self.root_dir_file(path)
      if path[1] == sep then path = path:sub(2) end

      local dirs = path:split(sep)
      local target = root
      dirs = table.n_filter(dirs, function(dir) return dir ~= "" end)

      local created = {}
      repeat
        local dir = table.remove(dirs, 1)
        target = ___.string.append(target, dir) .. sep

        if not self.dir_exists(target) then
          local ok, err, code = lfs.mkdir(target)
          if not ok and err and code ~= 17 then return nil, err, code end
          table.insert(created, target)
        end
      until #dirs == 0
      created = ___.table.map(created, function(_, dir) return self.fix_path(dir) end)
      return created, nil, nil
    end

    --- Determines the root of a path.
    ---@param path string The path to determine the root of.
    ---@return string|nil root The root of the path, or nil if the path is invalid.
    ---@example
    --- ```lua
    --- fd.determine_root("c:\\test\\moo")
    --- -- "c:"
    --- ```
    function self.determine_root(path)
      ___.v.type(path, "string", 1, false)

      path, _ = self.fix_path(path)

      local parts = { rex.match(path, "^([a-zA-Z]:(\\\\{1,2}|/{1,2})|/{1,2})(?:.*)$") }
      if not parts then return nil end

      local root, slash = parts[1], parts[2] or ""

      return root
    end

    --- Removes a file.
    ---@param path string The path to the file.
    ---@return boolean|nil removed Whether the file was removed, or nil on failure.
    ---@return string|nil err The error message, if the removal failed.
    ---@example
    --- ```lua
    --- fd.rmfile("path/to/file.txt")
    --- -- true
    --- ```
    function self.rmfile(path)
      ___.v.file(path, 1)

      return os.remove(path)
    end

    --- Removes a directory.
    ---@param path string The path to the directory.
    ---@return boolean|nil removed Whether the directory was removed, or nil on failure.
    ---@return string|nil err The error message, if the removal failed.
    ---@example
    --- ```lua
    --- fd.rmdir("path/to/directory")
    --- -- true
    --- ```
    function self.rmdir(path)
      ___.v.dir(path, 1)

      return lfs.rmdir(path)
    end

    --- Checks if a directory is empty.
    ---@param path string The path to the directory.
    ---@return boolean is_empty Whether the directory is empty.
    ---@example
    --- ```lua
    --- fd.dir_empty("/path/to/directory")
    --- -- true
    --- ```
    function self.dir_empty(path)
      return #self.get_dir(path, false) == 0
    end

    --- Gets the files in a directory.
    ---@param path string The path to the directory.
    ---@param include_dots boolean Whether to include the "." and ".." directories (default false).
    ---@return table result A table of files in the directory.
    ---@example
    --- ```lua
    --- fd.get_dir("/path/to/directory")
    --- -- {"file1", "file2", "file3"}
    --- ```
    function self.get_dir(path, include_dots)
      ___.v.type(path, "string", 1, false)
      ___.v.type(include_dots, "boolean", 2, true)

      include_dots = include_dots or false

      path, _ = self.fix_path(path)
      path = path or ""

      ___.v.dir(path, 1)

      local result = {}

      for file in lfs.dir(path) do
        local attr = lfs.attributes(path .. "/" .. file)
        table.insert(result, file)
      end

      if not include_dots then
        result = table.n_filter(result, function(file) return file ~= "." and file ~= ".." end)
      end

      ---@diagnostic disable-next-line: return-type-mismatch
      return result
    end

    --- Creates a unique temporary directory under the Mudlet home directory.
    --- The directory is placed at `<MudletHomeDir>/tmp/<id>` and created on disk.
    ---
    ---@return string|nil dir The path to the created temporary directory, or nil on failure.
    ---@return string|nil err The error message, if creation failed.
    ---@return number|nil code The error code, if creation failed.
    function self.temp_dir()
      local dir = getMudletHomeDir() .. "/tmp/" .. ___.id()

      local ok, err, code = self.assure_dir(dir)
      if not ok then return nil, err, code end

      return dir
    end
  end,
  valid = function(___, self)
    return {
      file = function(path, argument_index)
        ___.v.type(path, "string", argument_index, false)
        ___.v.type(argument_index, "number", 2, false)

        local attr = lfs.attributes(path)
        local last = ___.get_last_traceback_line()
        assert(attr ~= nil and attr.mode == "file", "Invalid value. " ..
          "Expected file, got " .. path .. " in\n" .. last)
      end,

      dir = function(path, argument_index)
        ___.v.type(path, "string", argument_index, false)
        ___.v.type(argument_index, "number", 2, false)

        local attr = lfs.attributes(path)
        local last = ___.get_last_traceback_line()
        assert(attr ~= nil and attr.mode == "directory", "Invalid value. " ..
          "Expected directory, got " .. path .. " in\n" .. last)
      end,

      path_string = function(path, argument_index, allow_nil)
        ___.v.type(path, "string", argument_index, false)
        ___.v.type(argument_index, "number", 2, false)
        ___.v.type(allow_nil, "boolean", 3, true)

        if allow_nil and path == nil then return end

        assert(self.valid_path_string(path), "Invalid value. " ..
          "Expected valid path string, got " .. path .. " in\n" ..
          ___.get_last_traceback_line())
      end,

      path_table = function(paths, argument_index, allow_nil)
        ___.v.uniform(paths, "string", 1, false)
        ___.v.type(allow_nil, "boolean", 2, true)

        allow_nil = allow_nil or false
        if allow_nil and #paths == 0 then return end

        assert(self.valid_path_table(paths), "Invalid value. " ..
          "Expected valid path table, got " .. ___.table.to_string(paths) ..
          " in\n" .. ___.get_last_traceback_line())
      end
    }
  end
})
