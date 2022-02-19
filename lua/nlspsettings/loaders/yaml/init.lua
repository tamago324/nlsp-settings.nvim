local schemas = require 'nlspsettings.schemas'
local tinyyaml = require 'nlspsettings.loaders.yaml.tinyyaml'

---@class nlspsettings.loaders.yaml
---@field name string loader name
---@field server_name string LSP server name
---@field settings_key string settings key
---@field file_ext string file extensions
local yaml = {
  name = 'yaml',
  server_name = 'yamlls',
  settings_key = 'yaml',
  file_ext = 'yml',
}

---
---@param path string
---@return string
yaml.load = function(path)
  local lines = vim.fn.readfile(path)
  -- see https://github.com/api7/lua-tinyyaml/pull/9
  if vim.tbl_isempty(lines) or (#lines == 1 and lines[1] == '') then
    return {}
  end

  local ok, result = pcall(tinyyaml.parse, table.concat(lines, '\n'))
  if ok then
    return result
  else
    return nil, result
  end
end

--- Return a list of default schemas
---@return table<string, string>
yaml.get_default_schemas = function()
  local res = {}
  for k, v in pairs(schemas.get_base_schemas_data()) do
    -- url: globpattern
    res[v] = k .. '.yml'
  end
  return res
end

return yaml
