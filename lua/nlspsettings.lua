local jsonls = require'nlspsettings.jsonls'
local config = require'nlspsettings.config'

local uv = vim.loop


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
    path = { path, 's' }
  }
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local decoded = json_decode(vim.fn.readfile(path))
  if decoded == nil then
    return
  end

  local name = string.match(path, '([^/]+)%.json$')
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
