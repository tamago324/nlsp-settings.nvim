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

  local cmd = (vim.api.nvim_buf_get_option(0, 'modified') and 'split') or 'edit'
  vim.api.nvim_command(string.format([[%s %s/%s.json]], cmd, home, langserver_name))
end

M.reload_config = function()
  nlspsettings.load_settings()
end

return M
