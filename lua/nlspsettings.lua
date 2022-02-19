local config = require 'nlspsettings.config'
local lspconfig = require 'lspconfig'
local utils = require 'nlspsettings.utils'

local uv = vim.loop

local M = {}

---@class nlspsettings.server_settings
---@field global_settings table
---@field conf_settings table

---@type table<string, nlspsettings.server_settings>
local servers = {}

---@type nlspsettings.loaders.json|nlspsettings.loaders.yaml
local loader

local loader_is_set = false

local set_loader = function()
  loader = require('nlspsettings.loaders.' .. config.get 'loader')
  loader_is_set = true
end


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

---設定ファイル名からサーバー名を取得する
---@param path string
---@return string
local get_server_name_from_path = function(path)
  return path:match '([^/]+)%.%w+$'
end

--- load settings from settings file
---@param path string settings file path
---@return boolean is_error if error then true
local load_global_setting = function(path)
  vim.validate {
    path = { path, 's' },
  }

  local name = get_server_name_from_path(path)
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
  local local_settings, err = load(
    string.format('%s/%s/%s.%s', root_dir, config.get 'local_settings_dir', server_name, loader.file_ext)
  )
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
    local settings_key = loader.settings_key
    -- もし、setup
    local s_schemas = settings[settings_key].schemas or {}

    -- XXX: 上でマージしているため、ここでは必要ない
    -- --- schemas をマージする
    -- local function merge(base_schemas, ext)
    --   if ext[settings_key] == nil or ext[settings_key]['schemas'] == nil then
    --     return base_schemas
    --   end
    --
    --   return utils.extend(base_schemas, ext[settings_key]['schemas'])
    -- end
    --
    -- s_schemas = merge(merge(merge(s_schemas, local_settings), global_settings), conf_settings)

    if config.get 'append_default_schemas' then
      s_schemas = utils.extend(s_schemas, loader.get_default_schemas())
    end

    settings[settings_key].schemas = s_schemas
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
    string.format('*/%s/*.%s', config.get 'local_settings_dir', loader.file_ext),
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

---path 以下にあるloaderに対応する設定ファイルのリストを返す
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

  set_loader()

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

---
---@return nlspsettings.loaders.json.jsonschema[]|table<string, string>
M.get_default_schemas = function()
  if not loader_is_set then
    set_loader()
  end

  return loader.get_default_schemas()
end

return setmetatable(M, mt)
