local uv = vim.loop


local script_abspath = function()
  return debug.getinfo(2, 'S').source:sub(2)
end
local _schemas_dir = script_abspath():match('(.*)/lua/nlspsettings/jsonls.lua$') .. '/schemas'

local M = {}

--- path のディレクトリ内にあるすべての *.json の設定を生成する
---@return table
local make_schemas_table = function(path)
  local handle = uv.fs_scandir(path)
  if handle == nil then
    return {}
  end

  local res = {}

  while true do
    local name, _ = uv.fs_scandir_next(handle)
    if name == nil then
      break
    end

    local server_name = string.match(name, '([^/]+)%.json$')
    if server_name ~= nil then
      res[server_name] = string.format('file://%s/%s', path, name)
    end
  end

  return res
end

local default_schemas = {}

local reset_default_schemas = function()
  local generated_schemas_table = make_schemas_table(_schemas_dir .. '/_generated')
  local local_schemas_table = make_schemas_table(_schemas_dir)
  default_schemas = vim.tbl_extend('force', generated_schemas_table, local_schemas_table)
end
reset_default_schemas()


--- Return a list of default schemas
---@return table
M.get_default_schemas = function()
  local res = {}

  for k, v in pairs(default_schemas) do
    table.insert(res, {
      fileMatch = { k .. '.json' },
      url = v
    })
  end

  return res
end


--- Return the name of a supported server.
---@return table
M.get_langserver_names = function()
  return vim.tbl_keys(default_schemas)
end


return M
