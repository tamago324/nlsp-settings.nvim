local defaults_values = {
  config_home = vim.fn.stdpath 'config' .. '/nlsp-settings',
  local_settings_dir = '.nlsp-settings',
  local_settings_root_markers_fallback = {
    '.git',
    '.nlsp-settings',
  },
  ignored_servers = {},
  append_default_schemas = false,
  open_strictly = false,
  nvim_notify = {
    enable = false,
    timeout = 5000,
  },
  loader = 'json',
}

---@class nlspsettings.config
---@field values nlspsettings.config.values
local config = {}

---@class nlspsettings.config.values
---@field config_home string:nil
---@field local_settings_dir string
---@field local_settings_root_markers_fallback string[]
---@field ignored_servers string[]
---@field append_default_schemas boolean
---@field open_strictly boolean
---@field nvim_notify nlspsettings.config.values.nvim_notify
---@field loader '"json"' | '"yaml"'
config.values = vim.deepcopy(defaults_values)

---@class nlspsettings.config.values.nvim_notify
---@field enable boolean
---@field timeout number

config.set_default_values = function(opts)
  config.values = vim.tbl_deep_extend('force', defaults_values, opts or {})

  -- For an empty table
  if not next(config.values.local_settings_root_markers_fallback) then
    config.values.local_settings_root_markers_fallback = defaults_values.local_settings_root_markers_fallback
  end
end

---
---@return nlspsettings.config.values
config.get = function()
  return config.values
end

return config
