local schemas = require 'nlspsettings.schemas'
local tinyyaml = require 'nlspsettings.deps.lua-tinyyaml.tinyyaml'

---@class nlspsettings.loaders.yaml
---@field server_name string
---@field name string
---@field settings_key string
---@field file_ext string
local yaml = {}
-- サーバー名
yaml.server_name = 'yamlls'
-- 設定言語の名前
yaml.name = 'yaml'
-- settings のキー
yaml.settings_key = 'yaml'
-- 設定ファイルの拡張子
yaml.file_ext = 'yml'

---
---@param path string
---@return string
yaml.load = function(path)
  local lines = vim.fn.readfile(path)
  -- see https://github.com/api7/lua-tinyyaml/pull/9
  if vim.tbl_isempty(lines) or (#lines == 1 and lines[1] == '') then
    return {}
  end
  return tinyyaml.parse(table.concat(lines, '\n'))
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