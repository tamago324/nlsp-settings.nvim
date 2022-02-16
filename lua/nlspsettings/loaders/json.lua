local schemas = require 'nlspsettings.schemas'

---@class nlspsettings.loaders.json
---@field server_name string
---@field name string
---@field settings_key string
---@field file_ext string
local json = {}
-- サーバー名
json.server_name = 'jsonls'
-- 設定言語の名前
json.name = 'json'
-- settings のキー
json.settings_key = 'json'
-- 設定ファイルの拡張子
json.file_ext = 'json'

--- Decodes from JSON.
---
---@param data string Data to decode
---@returns table json_obj Decoded JSON object
local json_decode = function(data)
  local ok, result = pcall(vim.fn.json_decode, data)
  if ok then
    return result
  else
    return nil, result
  end
end

---
---@param path string
---@return string
json.load = function(path)
  return json_decode(table.concat(vim.fn.readfile(path), "\n"))
end

--- Return a list of default schemas
---@return table
json.get_default_schemas = function()
  local res = {}
  for k, v in pairs(schemas.get_base_schemas_data()) do
    table.insert(res, {
      fileMatch = { k .. '.json' },
      url = v,
    })
  end

  return res
end

return json
