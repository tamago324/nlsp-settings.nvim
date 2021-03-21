local jsonls = require'nlspsettings.jsonls'
local config = require'nlspsettings.config'


local M = {}

-- _config_home = nil
local _config_home = vim.fn.stdpath('config')
local _settings = {}

local _setting_prefix_list = {
  sumneko_lua = { 'Lua' },
  jsonls = { 'json' },
  rust_analyzer = { 'rust', 'rust-client' },
  pyls = { 'pyls' }
}


--- テーブルの key の "." を階層にしたテーブルを返す
---
---@param t table
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
    path = { path, 's' }
  }
  if vim.fn.filereadable(path) == 0 then
    return
  end
  _settings = lsp_json_to_table(vim.fn.json_decode(vim.fn.readfile(path)))
end


M.setup = function(opts)
  vim.validate {
    opts = { opts, 't', true }
  }
  opts = opts or {}

  vim.validate {
    _config_home = { opts.config_home, 's', true }
  }

  config.set_default_values({
    config_home = opts.config_home
  })

  -- 設定を読み込む
  load_setting_json(config.get('config_home') .. '/nlsp-settings.json')
end


local get_langserver_settings = function(langserver_name)
  local prefix_list = _setting_prefix_list[langserver_name] or {}
  if prefix_list == nil then
    return {}
  end

  local res = {}
  for _, prefix in ipairs(prefix_list) do
    res[prefix] = _settings[prefix]
  end
  return res
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
    return vim.tbl_deep_extend('force', get_langserver_settings(k) or {}, settings)
  end

  return X
end


return setmetatable(M, mt)
