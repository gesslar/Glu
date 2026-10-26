local GitHubClass = Glu.glass.register({
  class_name = "GitHubClass",
  name = "github",
  extends = "http",
  setup = function(___, self)
    local gh_api_base = "https://api.github.com/repos/%s/%s/"

    function self.get_latest_release(owner, repo, cb)
      local url = string.format(gh_api_base .. "releases/latest", owner, repo)
      local response = self.get({ url = url }, function(response)
        if response.error then
          return cb(response.error)
        end
        local data = yajl.to_value(response.data)
        return cb(nil, data)
      end)

      return response
    end

    function self.get_latest_release_assets(owner, repo, cb)
      local response = self.get_latest_release(owner, repo, function(err, data)
        if err then return cb(err) end

        data = data or {}

        if table.size(data.assets) == 0 then
          return cb(nil, {})
        end

        return cb(nil, data.assets)
      end)

      return response
    end
  end
})
