local config = require'nlspsettings.config'
local lspconfig = require'lspconfig'
local util = require'nlspsettings.util'

local uv = vim.loop
local a = vim.api


local M = {}

local servers = {
  -- server_name = {
  --   global_settings = {},
  --   conf_settings = {}
  -- }
}


--- Decodes from JSON.
---
---@param data string Data to decode
---@returns table json_obj Decoded JSON object
local json_decode = function(data)
  local ok, result = pcall(vim.fn.json_decode, data)
  if ok then
    return result
  else
    return nil, result
  end
end

--- Convert table key dots to table nests
---
---@param t table JSON setting table
---@return table
local lsp_json_to_table = function(t)
  vim.validate {
    t = { t, 't' }
  }

  local res = {}

  for key, value in pairs(t) do
    local key_list = {}

    for k in string.gmatch(key, "([^.]+)") do
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
---@return table : json data
---@return boolean : error
local load = function(path)
  vim.validate {
    path = { path, 's' },
  }

  if vim.fn.filereadable(path) == 0 then
    return {}
  end

  local decoded, err = json_decode(vim.fn.readfile(path))
  if err ~= nil then
    return {}, true
  end
  if decoded == nil then
    return {}
  end

  return lsp_json_to_table(decoded) or {}
end

--- load settings from JSON file
---@param path string JSON file path
---@return boolean is_error if error then true
local load_global_setting_json = function(path)
  vim.validate {
    path = { path, 's' },
  }

  local name = path:match('([^/]+)%.json$')
  if servers[name] == nil then
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
---@return boolean : error when loading local settings
local get_settings = function(root_dir, server_name)
  local local_settings, err = load(string.format('%s/.nlsp-settings/%s.json', root_dir, server_name))
  local global_settings = servers[server_name].global_settings or {}
  local conf_settings = servers[server_name].conf_settings or {}

  -- Priority:
  --   1. local JSON settings
  --   2. global JSON settings
  --   3. setup({settings = ...})
  --   4. default_config.settings
  local res = vim.tbl_deep_extend('keep', vim.empty_dict(), local_settings)
  res = vim.tbl_deep_extend('keep', res, global_settings)
  res = vim.tbl_deep_extend('keep', res, conf_settings)
  return res, err
end

--- Read the JSON file and notify the server in workspace/didChangeConfiguration
---@param server_name string
M.update_settings = function(server_name)
  vim.validate {
    server_name = { server_name, 's' },
  }

  if #vim.lsp.get_active_clients() == 0 then
    -- on_new_config() が呼ばれたときに、読むから、JSON を読む必要はない
    return false
  end

  local err = load_global_setting_json(string.format('%s/%s.json', config.get('config_home'), server_name))
  if err then
    return true
  end

  local errors = false
  -- server_name のすべてのクライアントの設定を更新する
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == server_name then
      local new_settings, err_local = get_settings(client.config.root_dir, client.name)
      if err_local then
        errors = true
      end

      client.workspace_did_change_configuration(new_settings)
      -- Neovim 標準の workspace/configuration のハンドラで使っているため、常に同期を取るべき
      client.config.settings = new_settings
    end
  end

  return false
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


local setup = {}

--- load settings files under config_home
setup.load_settings = function()
  local files = get_settings_files(config.get('config_home'))
  for _, v in ipairs(files) do
    load_global_setting_json(v)
  end
end

--- Use on_new_config to enable automatic loading of JSON files on all language servers
setup.update_default_config = function()
  lspconfig.util.default_config = vim.tbl_extend(
    "force",
    lspconfig.util.default_config,
    {
      on_new_config = make_on_new_config(lspconfig.util.default_config.on_new_config)
    }
  )
end

setup.autocmds = function()
  local patterns = {
    string.format('*/%s/*.json', config.get('config_home'):match('[^/]+$')),
    '*/.nlsp-settings/*.json'
  }
  local pattern = table.concat(patterns, ',')

  vim.cmd( [[augroup NlspSettings]])
  vim.cmd( [[  autocmd!]])
  vim.cmd(([[  autocmd BufWritePost %s lua require'nlspsettings.command'._BufWritePost(vim.fn.expand('<afile>'))]]):format(pattern))
  vim.cmd( [[augroup END]])
end

--- Setup to read from a JSON file.
---@param opts table
M.setup = function(opts)
  vim.validate {
    opts = { opts, 't', true }
  }
  opts = opts or {}

  vim.validate {
    config_home = { opts.config_home, 's', true }
  }

  config.set_default_values({
    config_home = opts.config_home
  })

  -- XXX: ここで読む必要ある？？
  --      get_settings() で読めばいいのでは？
  setup.load_settings()
  setup.autocmds()
  setup.update_default_config()
end


M._get_servers = function()
  return servers
end

return M
