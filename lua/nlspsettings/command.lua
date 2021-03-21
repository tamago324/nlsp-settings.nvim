local config = require'nlspsettings.config'
local nlspsettings = require'nlspsettings'

local M = {}


M.open_config = function(langserver_name)
  vim.validate {
    langserver_name = { langserver_name, 's' }
  }

  local home = config.get('config_home')

  if vim.fn.isdirectory(home) == 0 then
    if vim.fn.confirm(string.format([[Config directory "%s" not exists, create?]], home), "&Yes\n&No", 1) ~= 1 then
      return
    end
    vim.fn.mkdir(home, 'p')
  end

  vim.api.nvim_command(string.format([[edit %s/%s.json]], home, langserver_name))
end

M.reload_config = function()
  nlspsettings.load_settings()
end

return M
