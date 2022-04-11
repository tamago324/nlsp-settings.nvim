local log = require 'nlspsettings.log'

local M = {}

M.open = function()
  log.warn ':NlspConfig has been removed in favor of :LspSettings {server_name}'
end

M.open_local = function()
  log.warn ':NlspLocalConfig has been removed in favor of :LspSettings local {server_name}'
end

M.open_buffer = function()
  log.warn ':NlspBufConfig has been removed in favor of :LspSettings buffer'
end

M.open_local_buffer = function()
  log.warn ':NlspLocalBufConfig has been removed in favor of :LspSettings buffer local'
end

M.update = function()
  log.warn ':NlspUpdateSettings has been removed in favor of :LspSettings update {server_name}'
end

return M
