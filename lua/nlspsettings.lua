local jsonls = require'nlspsettings.jsonls'
local config = require'nlspsettings.config'
local lspconfig = require'lspconfig'

local uv = vim.loop
local a = vim.api


local M = {}

local servers = {
  -- server_name = {
  --   settings = {},
  --   config_settings = {}
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

local load_setting_json = function(path)
  vim.validate {
    path = { path, 's' },
  }

  local name = path:match('([^/]+)%.json$')
  servers[name] = {}
  servers[name].settings = {}

  if vim.fn.filereadable(path) == 0 then
    return
  end

  local decoded, err = json_decode(vim.fn.readfile(path))
  if err ~= nil then
    return true
  end
  if decoded == nil then
    return
  end

  servers[name].settings = lsp_json_to_table(decoded) or {}
  servers[name].config_settings = {}
end

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

M.load_settings = function(path)
  local files = get_settings_files(config.get('config_home'))
  for _, v in ipairs(files) do
    load_setting_json(v)
  end
end

--- server_name.json を読み、 workspace/didChangeConfiguration でサーバーに通知する
---@param server_name any
M.update_settings = function(server_name)
  vim.validate {
    server_name = { server_name, 's' },
  }

  local err = load_setting_json(string.format('%s/%s.json', config.get('config_home'), server_name))
  if err then
    return true
  end

  -- Priority: JSON settings > setup() settings > default_config.settings
  local server = servers[server_name]
  local new_settings = vim.tbl_deep_extend('keep', server.settings, server.config_settings)
  local default_settings = lspconfig[server_name].document_config.default_config.settings
  new_settings = vim.tbl_deep_extend('keep', new_settings, default_settings or {})

  -- -- 新しく接続するクライアントのために設定する
  -- lspconfig[server_name].settings = new_settings

  -- server_name のすべてのクライアントの設定を更新する
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == server_name then
      client.workspace_did_change_configuration(new_settings)
      -- Neovim 標準の workspace/configuration のハンドラで使っているため、更新しておく
      -- see https://github.com/neovim/neovim/blob/55d6699dfd58edb53d32270a5a9a567a48ce7c08/runtime/lua/vim/lsp/handlers.lua#L160-L184
      client.config.settings = new_settings
    end
  end

  return false
end

M._setup_autocmds = function()
  local postfix = config.get('config_home'):match('[^/]+$')
  local pattern = string.format('*/%s/*.json', postfix)

  vim.cmd( [[augroup NlspSettings]])
  vim.cmd( [[  autocmd!]])
  vim.cmd(([[  autocmd BufWritePost %s lua require'nlspsettings.command'._BufWritePost(vim.fn.expand('<afile>'))]]):format(pattern))
  vim.cmd( [[augroup END]])
end

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

  M.load_settings()
  M._setup_autocmds()
end

local mt = {}

mt.__index = function(t, k)
  local X = {}

  X.get = function(settings)
    vim.validate {
      settings = { settings, 't', true }
    }

    settings = settings or {}
    servers[k].config_settings = settings
    return vim.tbl_deep_extend('keep', servers[k].settings or {}, settings)
  end

  return X
end

-- M.settings = servers
M._get_servers = function()
  return servers
end

return setmetatable(M, mt)
