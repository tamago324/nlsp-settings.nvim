local schemas_dir = os.getenv('PWD') .. '/schemas/_generated'

local write_tmpfile = function(data)
  local tmpname = os.tmpname()
  local file = io.open(tmpname, "w")
  file:write(data)
  file:close()
  return tmpname
end

local converters = {}
function convert_properties(json)
  return json.properties
end

converters.pylsp = convert_properties
converters.vtsls = convert_properties
converters.asm_lsp = convert_properties
converters.bright_script = convert_properties

converters.ast_grep = function(json)
  return json.definitions.Project.properties
end


-- 0: ok
-- 1: error
local gen_schema = function(url, server_name)
  local status_code = vim.fn.system('curl -Ss -o /dev/null -w "%{http_code}" ' .. url)
  if status_code == '404' then
    print('  not found url.')
    return 1
  end
  local json = vim.json.decode(vim.fn.system(string.format('curl -Ls %s', url)))
  local properties

  if json == nil then
    return 1
  end

  local converter = converters[server_name]
  if converter then
    properties = converter(json)
  else
    if json.contributes == nil then
      return 0
    end

    if vim.tbl_islist(json.contributes.configuration) then
      -- リストなら、 1つ目を取得する
      -- als がリストのため https://raw.githubusercontent.com/AdaCore/ada_language_server/master/integration/vscode/ada/package.json
      properties = json.contributes.configuration[1].properties
    elseif type(json.contributes.configuration) == 'table' then
      properties = json.contributes.configuration.properties
    end
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
  local gist_url = "https://gist.githubusercontent.com/tamago324/6c065d5914388ddddd9518bd8fb75c8c/raw/lsp-packages.json"
  local gist_res = vim.json.decode(vim.fn.system(string.format('curl -Ls "%s"', gist_url)))
  for server_name, url in pairs(gist_res) do
    print(server_name)
    local err = gen_schema(url, server_name)

    -- エラーがある場合、終了ステータスを1にして終了する
    if err then
      vim.cmd('cquit 1')
    end
  end
end

gen_schemas()
