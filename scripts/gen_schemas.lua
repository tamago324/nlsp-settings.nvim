require'lspconfig'
local configs = require 'lspconfig/configs'

local schemas_dir = os.getenv('PWD') .. '/schemas/_generated'

local function require_all_configs()
  local fin = false
  -- Configs are lazy-loaded, tickle them to populate the `configs` singleton.
  for _,v in ipairs(vim.fn.glob('nvim-lspconfig/lua/lspconfig/*.lua', 1, 1)) do
    local module_name = v:gsub('.*/', ''):gsub('%.lua$', '')
    require('lspconfig/'..module_name)
    fin = true
  end

  if fin then
    return
  end
end

local write_tmpfile = function(data)
  local tmpname = os.tmpname()
  local file = io.open(tmpname, "w")
  file:write(data)
  file:close()
  return tmpname
end

local gen_schema = function(url, server_name)
  local json = vim.fn.json_decode(vim.fn.system(string.format('curl -Ls %s', url)))
  local properties

  if json == nil or json.contributes == nil then
    return nil
  end

  if vim.tbl_islist(json.contributes.configuration) then
    -- リストなら、 1つ目を取得する
    -- als がリストのため https://raw.githubusercontent.com/AdaCore/ada_language_server/master/integration/vscode/ada/package.json
    properties = json.contributes.configuration[1].properties
  elseif type(json.contributes.configuration) == 'table' then
    properties = json.contributes.configuration.properties
  end

  local schema_data = vim.fn.json_encode({
    ['$schema'] = 'http://json-schema.org/draft-04/schema#',
    description = string.format('Setting of %s', server_name),
    properties = properties
  })

  local tmpfile = write_tmpfile(schema_data)
  vim.fn.system(string.format([[cat %s | jq -S > %s/%s.json]], tmpfile, schemas_dir, server_name))
  return vim.v.shellerror
end

local gen_schemas = function()
  for server_name, v in pairs(configs) do
    local docs = v.document_config.docs
    if docs and docs.package_json then
      print(server_name)
      local res = gen_schema(docs.package_json, server_name)
    end
  end
end

require_all_configs()
gen_schemas()
