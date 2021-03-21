local config = require'nlspsettings.config'


local M = {}


local schemas = {
  -- als                    = '',
  -- angularls              = '',
  -- bashls                 = '',
  -- beancount              = '',
  -- ccls                   = '',
  -- clangd                 = '',
  -- clojure_lsp            = '',
  -- cmake                  = '',
  -- codeqlls               = '',
  -- configs                = '',
  -- cssls                  = '',
  -- dartls                 = '',
  -- denols                 = '',
  -- dhall_lsp_server       = '',
  -- diagnosticls           = '',
  -- dockerls               = '',
  -- efm                    = '',
  -- elixirls               = '',
  -- elmls                  = '',
  -- erlangls               = '',
  -- flow                   = '',
  -- fortls                 = '',
  -- fsautocomplete         = '',
  -- gdscript               = '',
  -- ghcide                 = '',
  -- gopls                  = '',
  -- graphql                = '',
  -- groovyls               = '',
  -- haxe_language_server   = '',
  -- health                 = '',
  -- hie                    = '',
  -- hls                    = '',
  -- html                   = '',
  -- intelephense           = '',
  -- jdtls                  = '',
  -- jedi_language_server   = '',
  jsonls                 = 'https://raw.githubusercontent.com/tamago324/nlsp-settings.nvim/main/schemas/jsonls.json',
  -- julials                = '',
  -- kotlin_language_server = '',
  -- leanls                 = '',
  -- metals                 = '',
  -- nimls                  = '',
  -- ocamlls                = '',
  -- ocamllsp               = '',
  -- omnisharp              = '',
  -- perlls                 = '',
  -- phpactor               = '',
  -- powershell_es          = '',
  -- purescriptls           = '',
  pyls                   = 'https://raw.githubusercontent.com/tamago324/nlsp-settings.nvim/main/schemas/pyls.json',
  -- pyls_ms                = '',
  -- pyright                = '',
  -- r_language_server      = '',
  -- racket_langserver      = '',
  -- rls                    = '',
  -- rnix                   = '',
  -- rome                   = '',
  rust_analyzer          = 'https://raw.githubusercontent.com/tamago324/nlsp-settings.nvim/main/schemas/rust_analyzer.json',
  -- scry                   = '',
  -- solargraph             = '',
  -- sorbet                 = '',
  -- sourcekit              = '',
  -- sqlls                  = '',
  -- sqls                   = '',
  sumneko_lua            = 'https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json',
  -- svelte                 = '',
  -- terraformls            = '',
  -- texlab                 = '',
  -- tsserver               = '',
  -- vala_ls                = '',
  -- vimls                  = '',
  -- vls                    = '',
  -- vuels                  = '',
  -- yamlls                 = '',
  -- zls                    = '',
}


M.get_default_schemas = function()
  local res = {}

  for k, v in pairs(schemas) do
    table.insert(res, {
      fileMatch = { k .. '.json' },
      url = v
    })
  end

  return res
end


M.get_langserver_names = function()
  return vim.tbl_keys(schemas)
end

return M
