local uv = vim.loop

local path_sep = uv.os_uname().version:match 'Windows' and '\\' or '/'
local function join_paths(...)
  local result = table.concat({ ... }, path_sep)
  return result
end

local script_abspath = debug.getinfo(1, 'S').source:sub(2)
local pattern = join_paths('(.*)', 'lua', 'nlspsettings', 'schemas.lua$')
local nlsp_abstpath = script_abspath:match(pattern)
local _schemas_dir = join_paths(nlsp_abstpath, 'schemas')
local _generated_dir = join_paths(_schemas_dir, '_generated')

--- path のディレクトリ内にあるすべての *.json の設定を生成する
---@return table<string, string> { server_name: file_path }
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
      res[server_name] = string.format('/%s/%s', path, name)
    end
  end

  return res
end

-- ベースとなるスキーマの情報をリセットする
local base_schemas_data = {}
local reset_base_scemas_data = function()
  local generated_schemas_table = make_schemas_table(_generated_dir)
  local local_schemas_table = make_schemas_table(_schemas_dir)
  base_schemas_data = vim.tbl_extend('force', generated_schemas_table, local_schemas_table)
end
reset_base_scemas_data()

---ベースとなるスキーマを返す
---@return table<string, string> { server_name, file_path }
local get_base_schemas_data = function()
  return base_schemas_data
end

--- Return the name of a supported server.
---@return table
local get_langserver_names = function()
  return vim.tbl_keys(base_schemas_data)
end

return {
  get_base_schemas_data = get_base_schemas_data,
  get_langserver_names = get_langserver_names,
}
