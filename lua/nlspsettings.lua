local jsonls = require'nlspsettings.jsonls'
local config = require'nlspsettings.config'

local uv = vim.loop
local a = vim.api


local M = {}

local _settings = {}


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

  local name = string.match(path, '([^/]+)%.json$')
  _settings[name] = {}

  if vim.fn.filereadable(path) == 0 then
    return
  end

  local decoded, err = json_decode(vim.fn.readfile(path))
  if err ~= nil then
    return err
  end
  if decoded == nil then
    return nil
  end

  _settings[name] = lsp_json_to_table(decoded)
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


--- テーブルをマージする
---
---@param old_tbl table
---@param new_tbl table
---@return table
local merge_table
merge_table = function(old_tbl, new_tbl)
  local res = vim.deepcopy(old_tbl)

  for k, _ in pairs(new_tbl) do
    if old_tbl[k] ~= nil and type(old_tbl[k]) == 'table' and type(new_tbl[k]) == 'table' then
      res[k] = merge_table(res[k], new_tbl[k])
    else
      res[k] = new_tbl[k]
    end
  end

  return res
end

--- client.config.settings から 前の JSON の設定を消す
---
---@param client_settings table
---@param old_json_settings table
---@return table removed_client_settings
local remove_keys
remove_keys = function(client_settings, json_settings)
  local res = vim.deepcopy(client_settings)

  for k, _ in pairs(json_settings) do
    if res[k] ~= nil and type(res[k]) == 'table' and type(json_settings[k]) == 'table' then
      res[k] = remove_keys(res[k], json_settings[k])
    else
      -- remove
      res[k] = nil
    end
  end

  return res
end

--- server_name.json を読み、 workspace/didChangeConfiguration でサーバーに通知する
---@param server_name any
M.update_settings = function(server_name)
  vim.validate {
    server_name = { server_name, 's' },
  }

  local errors = nil

  -- server_name のすべてのクライアントの設定を更新する
  local reloaded_list = {}
  for _, bufnr in ipairs(a.nvim_list_bufs()) do
    vim.lsp.for_each_buffer_client(bufnr, function(client, client_id, _)

      if client.name == server_name and (not vim.tbl_contains(reloaded_list, client_id)) then
        -- 前の JSON の設定を消す
        -- XXX: 消すだけじゃだめかも... デフォルトの値を設定してあげないといけないかもしれない
        local settings = remove_keys(client.config.settings, _settings[server_name])

        -- 読み込む
        local err = load_setting_json(string.format('%s/%s.json', config.get('config_home'), server_name))
        if err ~= nil then
          errors = true
        end

        settings = merge_table(settings, _settings[server_name])
        client.workspace_did_change_configuration(settings)

        table.insert(reloaded_list, client_id)
      end
    end)
  end

  return errors
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
end

local mt = {}

-- nlspsettings.sumneko_lua.load()
mt.__index = function(t, k)
  local X = {}

  X.get = function(settings)
    vim.validate {
      settings = { settings, 't', true }
    }

    settings = settings or {}
    return vim.tbl_deep_extend('force', _settings[k] or {}, settings)
  end

  return X
end

M.settings = _settings

return setmetatable(M, mt)
