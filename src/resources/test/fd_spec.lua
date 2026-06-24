describe("fd module", function()
  local g
  local fixtures_dir
  local tmp_dirs = {}

  setup(function()
    g = Glu("Glu")
    fixtures_dir = getMudletHomeDir() .. "/Glu/test/fixtures"
  end)

  teardown(function()
    -- Clean up any temp dirs/files we created
    for i = #tmp_dirs, 1, -1 do
      pcall(lfs.rmdir, tmp_dirs[i])
    end
  end)

  -- ========================================================================
  -- fix_path
  -- ========================================================================

  describe("fix_path", function()
    it("should convert backslashes to forward slashes", function()
      local result = g.fd.fix_path("path\\to\\file.txt")
      assert.are.equal("path/to/file.txt", result)
    end)

    it("should collapse double forward slashes", function()
      local result = g.fd.fix_path("path//to//file.txt")
      assert.are.equal("path/to/file.txt", result)
    end)

    it("should preserve trailing slash", function()
      local result = g.fd.fix_path("path/to/dir/")
      assert.are.equal("path/to/dir/", result)
    end)

    it("should return unchanged path with no fixes needed", function()
      local path = "path/to/file.txt"
      local result, num = g.fd.fix_path(path)
      assert.are.equal(path, result)
    end)

    it("should handle empty string", function()
      local result = g.fd.fix_path("")
      assert.are.equal("", result)
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.fix_path(123)
      end)
    end)
  end)

  -- ========================================================================
  -- determine_path_separator
  -- ========================================================================

  describe("determine_path_separator", function()
    it("should detect forward slash", function()
      assert.are.equal("/", g.fd.determine_path_separator("path/to/file"))
    end)

    it("should detect backslash", function()
      assert.are.equal("\\", g.fd.determine_path_separator("path\\to\\file"))
    end)

    it("should prefer forward slash when both present", function()
      -- Searches / first in the ipairs
      assert.are.equal("/", g.fd.determine_path_separator("path/to\\file"))
    end)

    it("should return nil for no separator", function()
      assert.is_nil(g.fd.determine_path_separator("filename"))
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.determine_path_separator(123)
      end)
    end)
  end)

  -- ========================================================================
  -- determine_root
  -- ========================================================================

  describe("determine_root", function()
    it("should detect Unix root", function()
      assert.are.equal("/", g.fd.determine_root("/home/user/file"))
    end)

    it("should detect Windows root", function()
      local root = g.fd.determine_root("C:\\Users\\test")
      assert.is_truthy(root)
    end)

    it("should return nil for relative path", function()
      assert.is_nil(g.fd.determine_root("relative/path"))
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.determine_root(123)
      end)
    end)
  end)

  -- ========================================================================
  -- dir_file
  -- ========================================================================

  describe("dir_file", function()
    it("should split path into directory and file", function()
      local dir, file = g.fd.dir_file("path/to/file.txt")
      assert.are.equal("path/to", dir)
      assert.are.equal("file.txt", file)
    end)

    it("should handle single directory and file", function()
      local dir, file = g.fd.dir_file("dir/file.txt")
      assert.are.equal("dir", dir)
      assert.are.equal("file.txt", file)
    end)

    it("should handle backslashes by normalizing first", function()
      local dir, file = g.fd.dir_file("path\\to\\file.txt")
      assert.are.equal("path/to", dir)
      assert.are.equal("file.txt", file)
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.dir_file(123)
      end)
    end)

    it("should error on non-boolean dir_required", function()
      assert.has_error(function()
        g.fd.dir_file("path/to/file.txt", "yes")
      end)
    end)
  end)

  -- ========================================================================
  -- root_dir_file
  -- ========================================================================

  describe("root_dir_file", function()
    it("should split an absolute Unix path", function()
      local root, dir, file = g.fd.root_dir_file("/home/user/file.txt")
      assert.are.equal("/", root)
      assert.are.equal("home/user", dir)
      assert.are.equal("file.txt", file)
    end)

    it("should return nil for relative paths", function()
      local root, dir, file = g.fd.root_dir_file("relative/path/file.txt")
      assert.is_nil(root)
      assert.is_nil(dir)
      assert.is_nil(file)
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.root_dir_file(123)
      end)
    end)
  end)

  -- ========================================================================
  -- file_exists
  -- ========================================================================

  describe("file_exists", function()
    it("should return true for an existing file", function()
      assert.is_true(g.fd.file_exists(fixtures_dir .. "/sample.txt"))
    end)

    it("should return false for a non-existing file", function()
      assert.is_false(g.fd.file_exists(fixtures_dir .. "/nonexistent.txt"))
    end)

    it("should return false for a directory", function()
      assert.is_false(g.fd.file_exists(fixtures_dir))
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.file_exists(123)
      end)
    end)
  end)

  -- ========================================================================
  -- dir_exists
  -- ========================================================================

  describe("dir_exists", function()
    it("should return true for an existing directory", function()
      assert.is_true(g.fd.dir_exists(fixtures_dir))
    end)

    it("should return false for a non-existing directory", function()
      assert.is_false(g.fd.dir_exists(fixtures_dir .. "/nope"))
    end)

    it("should return false for a file", function()
      assert.is_false(g.fd.dir_exists(fixtures_dir .. "/sample.txt"))
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.dir_exists(123)
      end)
    end)
  end)

  -- ========================================================================
  -- read_file
  -- ========================================================================

  describe("read_file", function()
    it("should read a text file", function()
      local data = g.fd.read_file(fixtures_dir .. "/sample.txt")
      assert.are.equal("Hello, world!", data)
    end)

    it("should return nil for non-existing file", function()
      local data, err = g.fd.read_file(fixtures_dir .. "/nonexistent.txt")
      assert.is_nil(data)
      assert.is_truthy(err)
    end)

    it("should accept binary flag", function()
      local data = g.fd.read_file(fixtures_dir .. "/sample.txt", true)
      assert.are.equal("Hello, world!", data)
    end)

    it("should error on non-string path", function()
      assert.has_error(function()
        g.fd.read_file(123)
      end)
    end)

    it("should error on non-boolean binary flag", function()
      assert.has_error(function()
        g.fd.read_file(fixtures_dir .. "/sample.txt", "yes")
      end)
    end)
  end)

  -- ========================================================================
  -- read_json
  -- ========================================================================

  describe("read_json", function()
    it("should decode a JSON file into a table", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/sample.json")
      assert.is_nil(err)
      assert.is_truthy(data)
      assert.are.equal("Glu", data.name)
      assert.are.equal(3, data.count)
    end)

    it("should decode nested structures", function()
      local data = g.fd.read_json(fixtures_dir .. "/sample.json")
      assert.is_true(data.nested.enabled)
      assert.are.same({"a", "b", "c"}, data.nested.items)
    end)

    it("should return nil and an error for a non-existing file", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/nonexistent.json")
      assert.is_nil(data)
      assert.is_truthy(err)
    end)

    it("should return nil and an error for a directory", function()
      local data, err = g.fd.read_json(fixtures_dir)
      assert.is_nil(data)
      assert.is_truthy(err)
    end)

    it("should return nil and an error for malformed JSON", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/broken.json")
      assert.is_nil(data)
      assert.is_truthy(err)
    end)

    it("should error on non-string path", function()
      assert.has_error(function()
        g.fd.read_json(123)
      end)
    end)

    it("should error on nil path", function()
      assert.has_error(function()
        g.fd.read_json(nil)
      end)
    end)

    it("should decode a top-level array", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/array.json")
      assert.is_nil(err)
      assert.are.same({1, 2, 3}, data)
    end)

    it("should decode a top-level number", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/number.json")
      assert.is_nil(err)
      assert.are.equal(42, data)
    end)

    it("should decode a top-level string", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/string.json")
      assert.is_nil(err)
      assert.are.equal("hello", data)
    end)

    it("should decode a top-level boolean", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/bool.json")
      assert.is_nil(err)
      assert.is_true(data)
    end)

    it("should decode top-level null to the yajl.null sentinel, not nil", function()
      local data, err = g.fd.read_json(fixtures_dir .. "/null.json")
      assert.is_nil(err)
      -- A successful null decode is the yajl.null sentinel (userdata), which is
      -- distinct from the Lua nil returned on failure.
      assert.is_truthy(data)
      assert.are.equal(yajl.null, data)
    end)
  end)

  -- ========================================================================
  -- write_file
  -- ========================================================================

  describe("write_file", function()
    it("should write a new file", function()
      local tmp = g.fd.temp_dir()
      local path = tmp .. "/write_test.txt"
      local result = g.fd.write_file(path, "test data", true)
      assert.are.equal(path, result)

      -- Verify content
      local data = g.fd.read_file(path)
      assert.are.equal("test data", data)

      -- Cleanup
      os.remove(path)
      lfs.rmdir(tmp)
    end)

    it("should overwrite existing file when overwrite is true", function()
      local tmp = g.fd.temp_dir()
      local path = tmp .. "/overwrite_test.txt"
      g.fd.write_file(path, "original", true)
      g.fd.write_file(path, "replaced", true)

      local data = g.fd.read_file(path)
      assert.are.equal("replaced", data)

      -- Cleanup
      os.remove(path)
      lfs.rmdir(tmp)
    end)

    it("should append when overwrite is false", function()
      local tmp = g.fd.temp_dir()
      local path = tmp .. "/append_test.txt"
      g.fd.write_file(path, "first", false)
      g.fd.write_file(path, "second", false)

      local data = g.fd.read_file(path)
      assert.are.equal("firstsecond", data)

      -- Cleanup
      os.remove(path)
      lfs.rmdir(tmp)
    end)

    it("should return path and attributes on success", function()
      local tmp = g.fd.temp_dir()
      local path = tmp .. "/attrs_test.txt"
      local result_path, attrs = g.fd.write_file(path, "data", true)
      assert.are.equal(path, result_path)
      assert.is_truthy(attrs)
      assert.are.equal("file", attrs.mode)

      -- Cleanup
      os.remove(path)
      lfs.rmdir(tmp)
    end)

    it("should error on non-string path", function()
      assert.has_error(function()
        g.fd.write_file(123, "data")
      end)
    end)

    it("should error on non-string data", function()
      assert.has_error(function()
        g.fd.write_file("/tmp/test.txt", 123)
      end)
    end)
  end)

  -- ========================================================================
  -- valid_path_string
  -- ========================================================================

  describe("valid_path_string", function()
    it("should return true for path with forward slash", function()
      assert.is_true(g.fd.valid_path_string("path/to/file"))
    end)

    it("should return true for path with backslash", function()
      assert.is_true(g.fd.valid_path_string("path\\to\\file"))
    end)

    it("should return false for path with no separator", function()
      assert.is_false(g.fd.valid_path_string("filename"))
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.valid_path_string(123)
      end)
    end)
  end)

  -- ========================================================================
  -- valid_path
  -- ========================================================================

  describe("valid_path", function()
    it("should return true for existing file", function()
      assert.is_true(g.fd.valid_path(fixtures_dir .. "/sample.txt"))
    end)

    it("should return true for existing directory", function()
      assert.is_true(g.fd.valid_path(fixtures_dir))
    end)

    it("should return false for non-existing path", function()
      assert.is_false(g.fd.valid_path(fixtures_dir .. "/nope.txt"))
    end)
  end)

  -- ========================================================================
  -- get_dir
  -- ========================================================================

  describe("get_dir", function()
    it("should list files in a directory", function()
      local result = g.fd.get_dir(fixtures_dir)
      assert.is_truthy(result)
      assert.is_true(#result > 0)
    end)

    it("should exclude dot entries by default", function()
      local result = g.fd.get_dir(fixtures_dir)
      assert.is_nil(table.index_of(result, "."))
      assert.is_nil(table.index_of(result, ".."))
    end)

    it("should include dot entries when requested", function()
      local result = g.fd.get_dir(fixtures_dir, true)
      assert.is_truthy(table.index_of(result, "."))
      assert.is_truthy(table.index_of(result, ".."))
    end)

    it("should include sample.txt in fixtures listing", function()
      local result = g.fd.get_dir(fixtures_dir)
      assert.is_truthy(table.index_of(result, "sample.txt"))
    end)

    it("should include subdir in fixtures listing", function()
      local result = g.fd.get_dir(fixtures_dir)
      assert.is_truthy(table.index_of(result, "subdir"))
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.get_dir(123)
      end)
    end)
  end)

  -- ========================================================================
  -- dir_empty
  -- ========================================================================

  describe("dir_empty", function()
    it("should return false for non-empty directory", function()
      assert.is_false(g.fd.dir_empty(fixtures_dir))
    end)

    it("should return true for empty directory", function()
      local tmp = g.fd.temp_dir()
      assert.is_true(g.fd.dir_empty(tmp))
      lfs.rmdir(tmp)
    end)
  end)

  -- ========================================================================
  -- assure_dir
  -- ========================================================================

  describe("assure_dir", function()
    it("should create a directory that does not exist", function()
      local base = g.fd.temp_dir()
      local new_dir = base .. "/new_sub"
      local created = g.fd.assure_dir(new_dir)
      assert.is_truthy(created)
      assert.is_true(g.fd.dir_exists(new_dir))

      -- Cleanup
      lfs.rmdir(new_dir)
      lfs.rmdir(base)
    end)

    it("should create nested directories", function()
      local base = g.fd.temp_dir()
      local nested = base .. "/a/b/c"
      local created = g.fd.assure_dir(nested)
      assert.is_truthy(created)
      assert.is_true(g.fd.dir_exists(nested))

      -- Cleanup
      lfs.rmdir(base .. "/a/b/c")
      lfs.rmdir(base .. "/a/b")
      lfs.rmdir(base .. "/a")
      lfs.rmdir(base)
    end)

    it("should not error for already existing directory", function()
      assert.has_no.errors(function()
        g.fd.assure_dir(fixtures_dir)
      end)
    end)

    it("should error on non-string input", function()
      assert.has_error(function()
        g.fd.assure_dir(123)
      end)
    end)
  end)

  -- ========================================================================
  -- temp_dir
  -- ========================================================================

  describe("temp_dir", function()
    it("should create a temporary directory", function()
      local dir = g.fd.temp_dir()
      assert.is_truthy(dir)
      assert.is_true(g.fd.dir_exists(dir))

      -- Cleanup
      lfs.rmdir(dir)
    end)

    it("should create unique directories", function()
      local dir1 = g.fd.temp_dir()
      local dir2 = g.fd.temp_dir()
      assert.are_not.equal(dir1, dir2)

      -- Cleanup
      lfs.rmdir(dir1)
      lfs.rmdir(dir2)
    end)
  end)

  -- ========================================================================
  -- rmfile
  -- ========================================================================

  describe("rmfile", function()
    it("should remove an existing file", function()
      local tmp = g.fd.temp_dir()
      local path = tmp .. "/to_delete.txt"
      g.fd.write_file(path, "delete me", true)
      assert.is_true(g.fd.file_exists(path))

      local ok = g.fd.rmfile(path)
      assert.is_truthy(ok)
      assert.is_false(g.fd.file_exists(path))

      -- Cleanup
      lfs.rmdir(tmp)
    end)

    it("should error on non-existing file", function()
      assert.has_error(function()
        g.fd.rmfile("/nonexistent/path/file.txt")
      end)
    end)

    it("should error on directory path", function()
      assert.has_error(function()
        g.fd.rmfile(fixtures_dir)
      end)
    end)
  end)

  -- ========================================================================
  -- rmdir
  -- ========================================================================

  describe("rmdir", function()
    it("should remove an empty directory", function()
      local tmp = g.fd.temp_dir()
      assert.is_true(g.fd.dir_exists(tmp))

      local ok = g.fd.rmdir(tmp)
      assert.is_truthy(ok)
      assert.is_false(g.fd.dir_exists(tmp))
    end)

    it("should error on non-existing directory", function()
      assert.has_error(function()
        g.fd.rmdir("/nonexistent/path/dir")
      end)
    end)

    it("should error on file path", function()
      assert.has_error(function()
        g.fd.rmdir(fixtures_dir .. "/sample.txt")
      end)
    end)
  end)

  -- ========================================================================
  -- Validators
  -- ========================================================================

  describe("validators", function()
    describe("file validator", function()
      it("should pass for existing file (via rmfile)", function()
        local tmp = g.fd.temp_dir()
        local path = tmp .. "/valid_file.txt"
        g.fd.write_file(path, "test", true)
        assert.has_no.errors(function()
          g.fd.rmfile(path)
        end)
        lfs.rmdir(tmp)
      end)

      it("should fail for non-existing file (via rmfile)", function()
        assert.has_error(function()
          g.fd.rmfile("/does/not/exist.txt")
        end)
      end)
    end)

    describe("dir validator", function()
      it("should pass for existing directory (via rmdir)", function()
        local tmp = g.fd.temp_dir()
        assert.has_no.errors(function()
          g.fd.rmdir(tmp)
        end)
      end)

      it("should fail for non-existing directory (via rmdir)", function()
        assert.has_error(function()
          g.fd.rmdir("/does/not/exist/dir")
        end)
      end)
    end)
  end)
end)
