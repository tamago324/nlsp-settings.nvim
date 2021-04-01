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

M.reset_default_schemas = function()
  local generated_schemas_table = make_schemas_table(_schemas_dir .. '/_generated')
  local local_schemas_table = make_schemas_table(_schemas_dir)
  default_schemas = vim.tbl_extend('force', generated_schemas_table, local_schemas_table)
end

M.reset_default_schemas()

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


M.get_langserver_names = function()
  return vim.tbl_keys(default_schemas)
end


return M


-- local schemas = {
--   -- als                    = '',
--   -- angularls              = '',
--   bashls                 = 'file:///home/tamago324/ghq/github.com/tamago324/nlsp-settings.nvim/schemas/bashls.json',
--   -- beancount              = '',
--   -- ccls                   = '',
--   -- clangd                 = '',
--   -- clojure_lsp            = '',
--   -- cmake                  = '',
--   -- codeqlls               = '',
--   cssls                  = 'file:///home/tamago324/ghq/github.com/tamago324/nlsp-settings.nvim/schemas/cssls.json',
--   -- dartls                 = '',
--   -- denols                 = '',
--   -- dhall_lsp_server       = '',
--   -- diagnosticls           = '',
--   -- dockerls               = '',
--   -- efm                    = '',
--   -- elixirls               = '',
--   -- elmls                  = '',
--   -- erlangls               = '',
--   -- flow                   = '',
--   -- fortls                 = '',
--   -- fsautocomplete         = '',
--   -- gdscript               = '',
--   -- ghcide                 = '',
--   gopls                  = 'file:///home/tamago324/ghq/github.com/tamago324/nlsp-settings.nvim/schemas/gopls.json',
--   -- graphql                = '',
--   -- groovyls               = '',
--   -- haxe_language_server   = '',
--   -- health                 = '',
--   -- hie                    = '',
--   -- hls                    = '',
--   html                   = 'file:///home/tamago324/ghq/github.com/tamago324/nlsp-settings.nvim/schemas/html.json',
--   -- intelephense           = '',
--   -- jdtls                  = '',
--   -- jedi_language_server   = '',
--   -- jsonls                 = '',
--   -- julials                = '',
--   -- kotlin_language_server = '',
--   -- leanls                 = '',
--   -- metals                 = '',
--   -- nimls                  = '',
--   -- ocamlls                = '',
--   -- ocamllsp               = '',
--   -- omnisharp              = '',
--   -- perlls                 = '',
--   -- phpactor               = '',
--   -- powershell_es          = '',
--   -- purescriptls           = '',
--   -- pyls                   = '',
--   -- pyls_ms                = '',
--   -- pyright                = '',
--   -- r_language_server      = '',
--   -- racket_langserver      = '',
--   -- rls                    = '',
--   -- rnix                   = '',
--   -- rome                   = '',
--   -- rust_analyzer          = '',
--   -- scry                   = '',
--   -- solargraph             = '',
--   -- sorbet                 = '',
--   -- sourcekit              = '',
--   -- sqlls                  = '',
--   -- sqls                   = '',
--   -- sumneko_lua            = '',
--   -- svelte                 = '',
--   -- terraformls            = '',
--   -- texlab                 = '',
--   -- tsserver               = '',
--   -- vala_ls                = '',
--   -- vimls                  = '',
--   -- vls                    = '',
--   -- vuels                  = '',
--   -- yamlls                 = '',
--   -- zls                    = '',
-- }
