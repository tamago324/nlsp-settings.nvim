local defaults_values = {
  config_home = vim.fn.stdpath 'config' .. '/nlsp-settings',
  local_settings_root_markers = {
    '.git',
  },
  jsonls_append_default_schemas = false,
  nvim_notify = {
    enable = false,
    timeout = 5000,
  }
}

local config = {}
config.values = vim.deepcopy(defaults_values)

config.set_default_values = function(opts)
  config.values = vim.tbl_deep_extend('force', defaults_values, opts or {})

  -- For an empty table
  if not next(config.values.local_settings_root_markers) then
    config.values.local_settings_root_markers = defaults_values.local_settings_root_markers
  end
end

config.get = function(key)
  return config.values[key]
end

return config
