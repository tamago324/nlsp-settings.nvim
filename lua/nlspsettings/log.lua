local has_notify, notify = pcall(require, 'notify')
local config = require 'nlspsettings.config'

local TITLE = 'Lsp Settings'

--- Checks if can se nvim-notify integration
---@return
local use_nvim_notify = function()
  local notify_config = config.get().nvim_notify
  return has_notify and notify_config and notify_config.enable
end

--- Logs a message with the given log level.
---@param message string
---@param level number
local log = function(message, level)
  if use_nvim_notify() then
    notify(message, level, {
      title = TITLE,
      timeout = config.get().nvim_notify.timeout,
    })
  else
    vim.notify(('[%s] %s'):format(TITLE, message), level)
  end
end

--- Logs a message once with the given log level.
---@param message string
---@param level number
local log_once = function(message, level)
  -- users of nvim-notify may have `vim.notify = require("notify")`
  -- vim.notify_once uses vim.notify
  if use_nvim_notify() and vim.notify == notify then
    vim.notify_once(message, level, {
      title = TITLE,
      timeout = config.get().nvim_notify.timeout,
    })
  else
    vim.notify_once(('[%s] %s'):format(TITLE, message), level)
  end
end

--- Creates a logger from the given level.
---@param level string
local create_level = function(level)
  return function(message, once)
    if once then
      return log_once(message, level)
    end
    log(message, level)
  end
end

local M = {}

M.info = create_level(vim.log.levels.INFO)
M.warn = create_level(vim.log.levels.WARN)
M.error = create_level(vim.log.levels.ERROR)

return M
