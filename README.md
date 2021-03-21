# nlsp-settings.nvim

Make the Neovim LSP configurable using a json file like `coc-settings.json`.


By using `nlsp-settings.nvim`, the part of settings passed to `lspconfig.xxx.setup()` can be written in json file.
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


### Step 1. Configure `jsonls` to allow completion in settings json file.

[jsonls](https://github.com/vscode-langservers/vscode-json-languageserver) allows for configuration value completion.
(Currently, supported language servers are written in [schemas/READMD.md](https://github.com/tamago324/nlsp-settings.nvim/blob/main/schemas/README.md).)

```lua
require"lspconfig".jsonls.setup {
  cmd = {
    vim.fn.expand('/path/to/json-languageserver'),
    '--stdio'
  },

  -- Set the schema so that it can be completed in `nlsp-settings.json`.
  settings = {
    json = {
      schemas = vim.list_extend(require'nlspsettings.jsonls'.get_default_schemas(), {
        {
          fileMatch = {'.prettierrc', '.prettierrc.json', 'prettier.config.json'},
          url = 'http://json.schemastore.org/prettierrc'
        },
      })
    }
  }
}
```


### Step 2. Open the settings json file with `:NlspConfig` and write your settings.

Example) Settings the [sumneko_lua](https://github.com/sumneko/lua-language-server) settings:

`:NlspConfig sumneko_lua`

The default path for settings json file is `vim.fn.stdpath('config') .. '/nlsp-settings/*.json'`.
Create a configuration file in `~/.config/nvim/nlsp-settings/sumneko_lua.json` directly under config_home.

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

#### The path where settings json file is stored can be changed by the `config_home` argument of `nlspsettings.setup()`.


```lua
require'nlspsettings'.setup {
  config_home = vim.fn.stdpath('config') .. '/lspsettings'
}
```


### Step 3. Use `nlspsettings.xxx.get()` to read the settings from settings json file.

For `xxx`, specify the part of the settings file without the extension.

Example) To read [sumneko_lua](https://github.com/sumneko/lua-language-server) settings from settings json file:

```lua
-- You need to call setup().
local nlspsettings = require'nlspsettings'
nlspsettings.setup()

lspconfig.sumneko_lua.setup{
  cmd = { vim.fn.expand('/path/to/bin/Linux/lua-language-server'), '-E', vim.fn.expand('/path/to/main.lua'), },

  -- Use `nlspsettings.xxx.get()` to load the `settings` from `nlsp-settings.json`
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

-- -- Other language servers can also be read.
-- lspconfig.rust_analyzer.setup {
--   ...
--   settings = nlspsettings.rust_analyzer.get()
-- }
```


## Contributing

* If your language server lacks support, please feel free to make a pull request or issue.
* All contributions are welcome.


## License

MIT
