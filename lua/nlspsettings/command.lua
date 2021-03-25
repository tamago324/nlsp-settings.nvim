local config = require'nlspsettings.config'
local nlspsettings = require'nlspsettings'

local a = vim.api

local M = {}

M.open_config = function(server_name)
  vim.validate {
    server_name = { server_name, 's' }
  }

  local home = config.get('config_home')

  if vim.fn.isdirectory(home) == 0 then
    if vim.fn.confirm(string.format([[Config directory "%s" not exists, create?]], home), "&Yes\n&No", 1) ~= 1 then
      return
    end
    vim.fn.mkdir(home, 'p')
  end

  local cmd = (vim.api.nvim_buf_get_option(0, 'modified') and 'split') or 'edit'
  vim.api.nvim_command(string.format([[%s %s/%s.json]], cmd, home, server_name))
end

M.update_settings = function(server_name)
  local actived = false
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == server_name then
      actived = true
    end
  end

  vim.cmd [[redraw]]
  if not actived then
    -- a.nvim_echo({{string.format(' Nlsp[%s][Info] The server is not running, so it is not updating.', server_name), 'Normal'}}, false, {})
    return
  end

  local errors = nlspsettings.update_settings(server_name)
  if errors then
    a.nvim_echo({{string.format(' Nlsp[%s][Error] Failed to update the settings.', server_name), 'ErrorMsg'}}, false, {})
  else
    a.nvim_echo({{string.format(' Nlsp[%s][Info] Success to update the settings.', server_name), 'Normal'}}, false, {})
  end
end

M._BufWritePost = function(afile)
  if config.get('update_settings_on_save') then
    local server_name = string.match(afile, '([^/]+)%.json$')
    M.update_settings(server_name)
  end
end

return M
