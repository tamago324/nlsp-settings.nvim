local config = require'nlspsettings.config'
local nlspsettings = require'nlspsettings'
local lspconfig_util = require'lspconfig.util'

local a = vim.api
local uv = vim.loop

local M = {}

--- Get the path to the buffer number
---@param bufnr string
---@return string
local get_buffer_path = function(bufnr)
  local expr = (bufnr ~= nil and '#' .. bufnr) or '%'
  return vim.fn.expand(expr..':p')
end

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

--- open config file
---@param server_name string
---@param dir string
local open_config = function(dir, server_name)
  vim.validate {
    server_name = { server_name, 's' },
    dir = { dir, 's' }
  }

  if vim.fn.isdirectory(dir) == 0 then
    if vim.fn.confirm(string.format([[Config directory "%s" not exists, create?]], dir), "&Yes\n&No", 1) ~= 1 then
      return
    end
    vim.fn.mkdir(dir, 'p')
  end

  local path = string.format('%s/%s.json', dir, server_name)

  -- If the file does not exist, LSP will not be able to complete it, so create it
  do
    local stat = uv.fs_stat(path)
    local exists = not vim.tbl_isempty(stat or {})
    if not exists then
      local mode = tonumber('644', 8)
      local fd = uv.fs_open(path, "w", mode)
      if not fd then error('Could not create file: ' .. path) end
      uv.fs_close(fd)
    end
  end

  local cmd = (vim.api.nvim_buf_get_option(0, 'modified') and 'split') or 'edit'
  vim.api.nvim_command(string.format([[%s %s]], cmd, path))
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
  open_config(config.get('config_home'), server_name)
end

---Open the settings file for the specified server.
---@param server_name string
M.open_local_config = function(server_name)
  local start_path = get_buffer_path()
  if start_path == '' then
    start_path = vim.fn.getcwd()
  end

  local markers = config.get('local_settings_root_markers') or {}
  local root_dir = lspconfig_util.root_pattern(markers)(start_path)
  if root_dir == nil then
    a.nvim_echo({{string.format(' Nlsp[%s][Error] Failed to get root_dir.', server_name), 'ErrorMsg'}}, false, {})
    return
  end
  open_config(string.gsub(root_dir, '/$', '') .. '/.nlsp-settings', server_name)
end

--- Open a settings file that matches the current buffer
M.open_local_buf_config = function()
  local server = get_server_name()
  if server == nil then
    return
  end

  local client = vim.lsp.get_client_by_id(server.client_id)
  if client == nil then
    a.nvim_echo({{string.format(' Nlsp[%s][Error] Failed to get root_dir.', server.name), 'ErrorMsg'}}, false, {})
    return
  end
  local root_dir = client.config.root_dir

  open_config(root_dir .. '/.nlsp-settings', server.name)
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
