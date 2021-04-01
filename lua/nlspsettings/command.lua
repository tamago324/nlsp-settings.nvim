local config = require'nlspsettings.config'
local nlspsettings = require'nlspsettings'

local a = vim.api

local M = {}

--- Returns the name of the server connected to the current buffer.
---@param bufnr number? buffer number
---@return string server_name
local get_server_name = function(bufnr)
  vim.validate {
    bufnr = { bufnr, 'n', true }
  }

  local server_names = {}
  local clients = vim.lsp.buf_get_clients(bufnr)
  for _, _client in pairs(clients) do
    if not vim.tbl_contains(server_names, _client.name) then
      table.insert(server_names, _client.name)
    end
  end

  if #server_names == 0 then
    return
  end

  local server_name = server_names[1]
  if #server_names > 1 then
    local list = {}
    for i, v in ipairs(server_names) do
      table.insert(list, string.format('%d: %s', i, v))
    end

    table.insert(list, 1, 'Select server: ')
    local idx = vim.fn.inputlist(list)
    if idx == 0 then
      return
    end
    server_name = server_names[idx]
  end

  return server_name
end

--- Open a settings file that matches the current buffer
M.open_buf_config = function()
  local server_name = get_server_name()
  if server_name == nil then
    return
  end

  M.open_config(server_name)
end

---Open the settings file for the specified server.
---@param server_name string
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

---Update the setting values.
---@param server_name string
M.update_settings = function(server_name)
  vim.cmd [[redraw]]
  local errors = nlspsettings.update_settings(server_name)
  if errors then
    a.nvim_echo({{string.format(' Nlsp[%s][Error] Failed to update the settings.', server_name), 'ErrorMsg'}}, false, {})
  else
    a.nvim_echo({{string.format(' Nlsp[%s][Info] Success to update the settings.', server_name), 'Normal'}}, false, {})
  end
end


---What to do when BufWritePost fires
---@param afile string
M._BufWritePost = function(afile)
  local server_name = string.match(afile, '([^/]+)%.json$')
  M.update_settings(server_name)
end


return M
