local has_notify, notify = pcall(require, 'notify')
local config = require 'nlspsettings.config'

local M = {}

--- Logs a message with the given log level.
---@param message string
---@param level number
M.log = function(message, level)
  local title = 'NLsp Settings'
  local notify_config = config.get().nvim_notify

  if notify and notify_config and notify_config.enable then
    notify(message, level, {
      title = title,
      timeout = notify_config.timeout,
    })
  else
    vim.notify(('[%s] %s'):format(title, message), level)
  end
end

return M
