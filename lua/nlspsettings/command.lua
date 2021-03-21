local config = require'nlspsettings.config'
local nlspsettings = require'nlspsettings'

local M = {}


M.open_config = function()
  local home = config.get('config_home')

  if vim.fn.isdirectory(home) == 0 then
    if vim.fn.confirm(string.format([[Config directory "%s" not exists, create?]], home), "&Yes\n&No", 1) ~= 1 then
      return
    end
    vim.fn.mkdir(home, 'p')
  end

  vim.api.nvim_command('edit ' .. home .. '/nlsp-settings.json')
end

M.reload_config = function()
  load_setting_json(config.get('config_home') .. '/nlsp-settings.json')
end

return M
