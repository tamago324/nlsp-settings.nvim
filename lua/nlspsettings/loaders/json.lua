local schemas = require 'nlspsettings.schemas'

---@class nlspsettings.loaders.json
---@field name string loader name
---@field server_name string LSP server name
---@field settings_key string settings key
---@field file_ext string file extensions
local json = {
  name = 'json',
  server_name = 'jsonls',
  settings_key = 'json',
  file_ext = 'json',
}

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
  return json_decode(table.concat(vim.fn.readfile(path), '\n'))
end

---@class nlspsettings.loaders.json.jsonschema
---@field fileMatch string|string[]
---@field url string

--- Return a list of default schemas
---@return nlspsettings.loaders.json.jsonschema[]
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
