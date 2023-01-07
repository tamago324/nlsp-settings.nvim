# nlsp-settings.nvim

[![gen_schemas](https://github.com/tamago324/nlsp-settings.nvim/actions/workflows/gen_schemas.yml/badge.svg)](https://github.com/tamago324/nlsp-settings.nvim/actions/workflows/gen_schemas.yml)

A plugin to configure Neovim LSP using json/yaml files like `coc-settings.json`.

  <img src="https://github.com/tamago324/images/blob/master/nlsp-settings.nvim/sumneko_lua_completion.gif" alt="sumneko_lua_completion.gif" width="600" style=""/>

<sub>Using `nlsp-settings.nvim` and [lspconfig](https://github.com/neovim/nvim-lspconfig/) and [jsonls](https://github.com/vscode-langservers/vscode-json-languageserver/) and [nvim-compe](https://github.com/hrsh7th/nvim-compe/) and [vim-vsnip](https://github.com/hrsh7th/vim-vsnip/)</sub>


Using `nlsp-settings.nvim`, you can write some of the `settings` to be passed to `lspconfig.xxx.setup()` in a json file.
You can also use it with [jsonls](https://github.com/vscode-langservers/vscode-json-languageserver) to complete the configuration values.



## Requirements

* Neovim
* [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/)


## Installation

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'tamago324/nlsp-settings.nvim'

" Recommend
Plug 'williamboman/nvim-lsp-installer'

" Optional
Plug 'rcarriga/nvim-notify'
```

## Getting Started

### Step 1. Install jsonls with nvim-lsp-installer

```
:LspInstall jsonls
```

### Step 2. Setup LSP servers

Example: Completion using omnifunc

```lua
local lsp_installer = require('nvim-lsp-installer')
local lspconfig = require("lspconfig")
local nlspsettings = require("nlspsettings")

nlspsettings.setup({
  config_home = vim.fn.stdpath('config') .. '/nlsp-settings',
  local_settings_dir = ".nlsp-settings",
  local_settings_root_markers_fallback = { '.git' },
  append_default_schemas = true
  loader = 'json'
})

function on_attach(client, bufnr)
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
end

local global_capabilities = vim.lsp.protocol.make_client_capabilities()
global_capabilities.textDocument.completion.completionItem.snippetSupport = true

lspconfig.util.default_config = vim.tbl_extend("force", lspconfig.util.default_config, {
  capabilities = global_capabilities,
})

lsp_installer.on_server_ready(function(server)
  server:setup({
    on_attach = on_attach
  })
end)
```

TODO: その他の設定は doc を参照


### Step 3. Write settings

Execute `:LspSettings sumneko_lua`.  
`sumneko_lua.json` will be created under the directory set in `config_home`. Type `<C-x><C-o>`. You should now have jsonls completion enabled.

> :exclamation: Each time Neovim is opened, `:LspSettings update [server_name]` must be executed *after the LSP server attaches*

## Usage

### LspSettings command

* `:LspSettings [server_name]`:  Open the global settings file for the specified `{server_name}`.
* `:LspSettings buffer`: Open the global settings file that matches the current buffer.
* `:LspSettings local [server_name]`: Open the local settings file of the specified `{server_name}` corresponding to the cwd.
* `:LspSettings local buffer` or `LspSettings buffer local`:  Open the local settings file of the server corresponding to the current buffer.
* `:LspSettings update [server_name]`: Update the setting values for the specified `{server_name}`.

For a list of language servers that have JSON Schema, see [here](schemas/README.md).


### Settings files for each project

You can create a settings file for each project with the following command.

* `:LspSettings local [server_name]`.
* `:LspSettings update [server_name]`

The settings file will be created in `{project_path}/.nlsp-settings/{server_name}.json`.


### Combine with Lua configuration

It is still possible to write `settings` in lua.
However, if you have the same key, the value in the JSON file will take precedence.

Example) Write sumneko_lua settings in Lua

```lua
local server_opts = {}

-- lua
server_opts.sumneko_lua = {
  settings = {
    Lua = {
      workspace = {
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. '/lua'] = true,
        }
      }
    }
  }
}

local common_setup_opts = {
  -- on_attach = on_attach,
  -- capabilities = require('cmp_nvim_lsp').update_capabilities(
  --   vim.lsp.protocol.make_client_capabilities()
  -- )
}

lsp_installer.on_server_ready(function(server)
  local opts = vim.deepcopy(common_setup_opts)
  if server_opts[server.name] then
      opts = vim.tbl_deep_extend('force', opts, server_opts[server.name])
  end
  server:setup(opts)
end)
```


## Contributing

* All contributions are welcome.


## License

MIT
