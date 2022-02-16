local config = require 'nlspsettings.config'
local lspconfig = require 'lspconfig'

local uv = vim.loop

local M = {}

local servers = {
  -- server_name = {
  --   global_settings = {},
  --   conf_settings = {}
  -- }
}

---@type nlspsettings.loaders.json|nlspsettings.loaders.yaml
local loader

--- Convert table key dots to table nests
---
---@param t table settings setting table
---@return table
local lsp_table_to_lua_table = function(t)
  vim.validate {
    t = { t, 't' },
  }

  local res = {}

  for key, value in pairs(t) do
    local key_list = {}

    for k in string.gmatch(key, '([^.]+)') do
      table.insert(key_list, k)
    end

    local tbl = res
    for i, k in ipairs(key_list) do
      if i == #key_list then
        tbl[k] = value
      end
      if tbl[k] == nil then
        tbl[k] = {}
      end
      tbl = tbl[k]
    end
  end

  return res
end

--- load settings file
---@param path string
---@return table json data
---@return boolean error
local load = function(path)
  vim.validate {
    path = { path, 's' },
  }

  if vim.fn.filereadable(path) == 0 then
    return {}
  end

  local data, err = loader.load(path)
  if err ~= nil then
    return {}, true
  end
  if data == nil then
    return {}
  end

  return lsp_table_to_lua_table(data) or {}
end

--- load settings from settings file
---@param path string settings file path
---@return boolean is_error if error then true
local load_global_setting = function(path)
  vim.validate {
    path = { path, 's' },
  }

  -- TODO: loader.extensions で回す
  -- キャプチャしたものを取得したいため、関数を呼び出している
  local name = path:gmatch('([^/]+)%.' .. loader.file_ext .. '$')()
  if name == nil then
    return
  end

  if name and servers[name] == nil then
    servers[name] = {}
    servers[name].global_settings = {}
    servers[name].conf_settings = {}
  end

  local data, err = load(path)
  if err then
    return err
  end
  servers[name].global_settings = data
end

--- Returns the current settings for the specified server
---@param root_dir string
---@param server_name string
---@return table merged_settings
---@return boolean error when loading local settings
local get_settings = function(root_dir, server_name)
  local local_settings, err = load(string.format('%s/%s/%s.%s', config.get('local_settings_dir'), root_dir, server_name, loader.file_ext))
  local global_settings = servers[server_name].global_settings or {}
  local conf_settings = servers[server_name].conf_settings or {}

  -- Priority:
  --   1. local settings
  --   2. global settings
  --   3. setup({settings = ...})
  --   4. default_config.settings
  local settings = vim.empty_dict()
  settings = vim.tbl_deep_extend('keep', settings, local_settings)
  settings = vim.tbl_deep_extend('keep', settings, global_settings)
  settings = vim.tbl_deep_extend('keep', settings, conf_settings)

  -- jsonls の場合、 schemas を追加する
  if server_name == loader.server_name then
    local schema_data = {}
    local settings_key = loader.settings_key

    if local_settings[settings_key] ~= nil and local_settings[settings_key]['schemas'] then
      schema_data = vim.list_extend(schema_data, local_settings[settings_key].schemas or {})
    end
    if conf_settings[settings_key] ~= nil and conf_settings[settings_key]['schemas'] then
      schema_data = vim.list_extend(schema_data, conf_settings[settings_key].schemas or {})
    end
    if global_settings[settings_key] ~= nil and global_settings[settings_key]['schemas'] then
      schema_data = vim.list_extend(schema_data, global_settings[settings_key].schemas or {})
    end

    -- if config.get 'jsonls_append_default_schemas' then
    --   schema_data = vim.list_extend(schema_data, schema_data.get_default_schemas() or {})
    -- end

    settings[settings_key].schemas = schema_data
  end
  return settings, err
end
M.get_settings = get_settings

--- Read the settings file and notify the server in workspace/didChangeConfiguration
---@param server_name string
M.update_settings = function(server_name)
  vim.validate {
    server_name = { server_name, 's' },
  }

  if #vim.lsp.get_active_clients() == 0 then
    -- on_new_config() が呼ばれたときに読むから、設定ファイルを読む必要はない
    return false
  end

  -- もしかしたら、グローバルの設置が変わっている可能性があるため、ここで読み込む
  local err = load_global_setting(string.format('%s/%s.%s', config.get 'config_home', server_name, loader.file_ext))
  if err then
    return true
  end

  local errors = false

  -- server_name のすべてのクライアントの設定を更新する
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == server_name then
      -- 設定ファイルの設定と setup() の設定をマージする
      -- 各クライアントの設定を読み込みたいため、ループの中で読み込む
      local new_settings, err_ = get_settings(client.config.root_dir, server_name)
      if err_ then
        errors = true
      end

      -- XXX: なぜか、エラーになる...
      -- client.workspace_did_change_configuration(new_settings)
      client.notify('workspace/didChangeConfiguration', {
        settings = new_settings,
      })

      -- Neovim 標準の workspace/configuration のハンドラで使っているため、常に同期を取るべき
      client.config.settings = new_settings
    end
  end

  return errors
end

--- Make an on_new_config function that sets the settings
---@param on_new_config function
---@return function
local make_on_new_config = function(on_new_config)
  -- before にしたのは、settings を上書きできるようにするため
  -- XXX: before か after かどっちがいいのか、なやむ
  return lspconfig.util.add_hook_before(on_new_config, function(new_config, root_dir)
    local server_name = new_config.name

    if servers[server_name] == nil then
      servers[server_name] = {}
    end

    -- 1度だけ、保持する ()
    -- new_config.settings は `setup({settings = ...}) + default_config.settings`
    servers[server_name].conf_settings = vim.deepcopy(new_config.settings)
    new_config.settings = get_settings(root_dir, server_name)
  end)
end

local setup_autocmds = function()
  local patterns = {
    string.format('*/%s/*.%s', config.get('config_home'):match '[^/]+$', loader.file_ext),
    string.format('*/%s/*.%s', config.get('local_settings_dir'), loader.file_ext),
  }
  local pattern = table.concat(patterns, ',')

  vim.cmd [[augroup NlspSettings]]
  vim.cmd [[  autocmd!]]
  vim.cmd(
    ([[  autocmd BufWritePost %s lua require'nlspsettings.command'._BufWritePost(vim.fn.expand('<afile>'))]]):format(
      pattern
    )
  )
  vim.cmd [[augroup END]]
end

--- Returns a list of settings files under path
---@param path string config_home
---@return table settings_files List of settings file
local get_settings_files = function(path)
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
    table.insert(res, path .. '/' .. name)
  end

  return res
end

--- load settings files under config_home
local load_settings = function()
  local files = get_settings_files(config.get 'config_home')
  for _, v in ipairs(files) do
    load_global_setting(v)
  end
end

--- Use on_new_config to enable automatic loading of settings files on all language servers
local setup_default_config = function()
  lspconfig.util.default_config = vim.tbl_extend('force', lspconfig.util.default_config, {
    on_new_config = make_on_new_config(lspconfig.util.default_config.on_new_config),
  })
end

--- Setup to read from a settings file.
---@param opts nlspsettings.config.values
M.setup = function(opts)
  vim.validate {
    opts = { opts, 't', true },
  }
  opts = opts or {}

  config.set_default_values(opts)

  loader = require('nlspsettings.loaders.' .. config.get('loader'))

  -- XXX: ここで読む必要ある？？
  --      get_settings() で読めばいいのでは？
  load_settings()
  setup_autocmds()
  setup_default_config()
end

local mt = {}

-- M.settings = servers
M._get_servers = function()
  return servers
end

return setmetatable(M, mt)
