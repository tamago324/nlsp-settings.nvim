require'lspconfig'
local configs = require 'lspconfig/configs'
local uv = vim.loop

local _schemas_dir = os.getenv('PWD') .. '/schemas'


local function require_all_configs()
  local fin = false
  -- Configs are lazy-loaded, tickle them to populate the `configs` singleton.
  for _,v in ipairs(vim.fn.glob('nvim-lspconfig/lua/lspconfig/server_configurations/*.lua', 1, 1)) do
    local module_name = v:gsub('.*/', ''):gsub('%.lua$', '')

    -- vim.fn.getcwd() が使われているため、必ずエラーになってしまうため、その対応
    if module_name ~= 'glint' then
      configs[module_name] = require('lspconfig.server_configurations.'..module_name)
      fin = true
    end
  end

  if fin then
    return
  end
end


local exists_json
exists_json = function(server_name, path)
  local handle = uv.fs_scandir(path)
  if handle == nil then
    return false
  end

  local res = false
  while true do
    local name, _ = uv.fs_scandir_next(handle)
    if name == nil then
      break
    end

    if vim.fn.isdirectory(path .. '/' .. name) == 1 then
      res = exists_json(server_name, path .. '/' .. name)
    end

    local sname = string.match(name, '([^/]+)%.json$')
    if sname == server_name then
      res = true
    end
  end

  return res
end

local write_readme = function(lines)
  local file = io.open('schemas/README.md', "w")
  file:write(table.concat(lines, '\n'))
  file:close()
end

local main = function()
  local lines = {}
  table.insert(lines, '# Schemas')
  table.insert(lines, '')

  local server_names = vim.tbl_keys(configs)
  table.sort(server_names)

  for _, server_name in ipairs(server_names) do
    local checked = (exists_json(server_name, _schemas_dir) and 'x') or ' '
    table.insert(lines, string.format('- [%s] %s', checked, server_name))
  end
  write_readme(lines)
end

require_all_configs()
main()
