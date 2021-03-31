# nlsp-settings.nvim

A plugin to configure Neovim LSP using json files like `coc-settings.json`.

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
```


## Usage


### Step1. Configure jsonls.

[jsonls](https://github.com/vscode-langservers/vscode-json-languageserver) allows for configuration value completion.  

```lua
require"lspconfig".jsonls.setup {
  cmd = { '/path/to/json-languageserver', '--stdio' },

  -- Set the schema so that it can be completed in settings json file.
  settings = {
    json = {
      schemas = require'nlspsettings.jsonls'.get_default_schemas()
    }
  }
}
```


### Step2. Write settings.

For a list of language servers that have JSON Schema, see [here](schemas/README.md).

Example) Settings the [sumneko_lua](https://github.com/sumneko/lua-language-server) settings:

`:NlspConfig sumneko_lua`

Create a settings file in `~/.config/nvim/nlsp-settings/sumneko_lua.json`.

```json
{
  "Lua.runtime.version": "LuaJIT",
  "Lua.diagnostics.enable": true,
  "Lua.diagnostics.globals": [
    "vim", "describe", "it", "before_each", "after_each"
  ],
  "Lua.diagnostics.disable": [
    "unused-local", "unused-vararg", "lowercase-global", "undefined-field"
  ],
  "Lua.completion.callSnippet": "Both",
  "Lua.completion.keywordSnippet": "Both"
}
```

NOTE: The path where settings json file is stored can be changed by the `config_home` argument of `nlspsettings.setup()`.


```lua
require'nlspsettings'.setup {
  config_home = vim.fn.stdpath('config') .. '/lspsettings'

  -- When saved, it will use workspace/didChangeConfiguration to notify the server of the configuration.
  -- update_settings_on_save = true
}
```


### Step 3. Load settings.

Example) To load sumneko_lua settings from settings json file:

```lua
-- You need to call setup().
local nlspsettings = require'nlspsettings'
nlspsettings.setup()

lspconfig.sumneko_lua.setup{
  cmd = { '/path/to/bin/Linux/lua-language-server', '-E', '/path/to/main.lua', },

  -- Use `nlspsettings.xxx.get()` to load the `settings` from `sumneko_lua.json`
  settings = nlspsettings.sumneko_lua.get()

  -- -- It is also possible to merge other `settings` by passing the table.
  -- settings = nlspsettings.sumneko_lua.get {
  --   Lua = {
  --     workspace = {
  --       library = {
  --         [vim.fn.expand("$VIMRUNTIME/lua")] = true,
  --         [vim.fn.stdpath("config") .. '/lua'] = true,
  --       }
  --     }
  --   }
  -- }
}
```


## Contributing

* If your language server lacks support, please feel free to make a pull request or issue.
* All contributions are welcome.


## License

MIT
