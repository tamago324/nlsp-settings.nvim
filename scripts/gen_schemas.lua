local schemas_dir = os.getenv('PWD') .. '/schemas/_generated'

local write_tmpfile = function(data)
  local tmpname = os.tmpname()
  local file = io.open(tmpname, "w")
  file:write(data)
  file:close()
  return tmpname
end

local gen_schema = function(url, server_name)
  local json = vim.json.decode(vim.fn.system(string.format('curl -Ls %s', url)))
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

  local schema_data = vim.json.encode({
    ['$schema'] = 'http://json-schema.org/draft-04/schema#',
    description = string.format('Setting of %s', server_name),
    properties = properties
  })

  local tmpfile = write_tmpfile(schema_data)
  vim.fn.system(string.format([[cat %s | jq -S > %s/%s.json]], tmpfile, schemas_dir, server_name))
  return vim.v.shellerror
end

local gen_schemas = function()
  local gist_url = "https://gist.githubusercontent.com/williamboman/a01c3ce1884d4b57cc93422e7eae7702/raw/lsp-packages.json"
  local gist_res = vim.json.decode(vim.fn.system(string.format('curl -Ls "%s"', gist_url)))
  for server_name, url in pairs(gist_res) do
    print(server_name)
    local res = gen_schema(url, server_name)
  end
end

gen_schemas()
