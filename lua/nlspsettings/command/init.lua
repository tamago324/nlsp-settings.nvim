local config = require 'nlspsettings.config'
local parser = require 'nlspsettings.command.parser'
local nlspsettings = require 'nlspsettings'
local lspconfig = require 'lspconfig'
local log = require 'nlspsettings.log'

local path = lspconfig.util.path
local uv = vim.loop

local M = {}

--- Get the path to the buffer number
---@param bufnr number?
---@return string
local get_buffer_path = function(bufnr)
  local expr = (bufnr ~= nil and '#' .. bufnr) or '%'
  return vim.fn.expand(expr .. ':p')
end

--- Calls the callback with the name of the server connected to the given buffer.
---@param bufnr number?
---@param callback function
local with_server_name = function(bufnr, callback)
  vim.validate {
    bufnr = { bufnr, 'n', true },
  }

  local server_names = {}
  local clients = vim.lsp.buf_get_clients(bufnr)
  for _, _client in pairs(clients) do
    if
      not vim.tbl_contains(server_names, _client.name)
      and not vim.tbl_contains(config.get().ignored_servers, _client.name)
    then
      table.insert(server_names, _client.name)
    end
  end

  if not next(server_names) then
    return
  end

  if #server_names > 1 then
    vim.ui.select(server_names, { prompt = 'Select server:' }, callback)
  else
    callback(server_names[1])
  end
end

--- open config file
---@param dir string
---@param server_name string
local open = function(dir, server_name)
  vim.validate {
    server_name = { server_name, 's' },
    dir = { dir, 's' },
  }

  if not path.is_dir(dir) then
    local prompt = ('Config directory "%s" not exists, create?'):format(path.sanitize(dir))

    if vim.fn.confirm(prompt, '&Yes\n&No', 1) ~= 1 then
      return
    end

    uv.fs_mkdir(dir, tonumber('700', 8))
  end

  local loader = require('nlspsettings.loaders.' .. config.get().loader)
  local filepath = path.join(dir, server_name .. '.' .. loader.file_ext)

  -- If the file does not exist, LSP will not be able to complete it, so create it
  if not path.is_file(filepath) then
    local fd = uv.fs_open(filepath, 'w', tonumber('644', 8))

    if not fd then
      log.error('Could not create file: ' .. filepath)
      return
    end

    uv.fs_close(fd)
  end

  local cmd = (vim.api.nvim_buf_get_option(0, 'modified') and 'split') or 'edit'
  vim.api.nvim_command(cmd .. ' ' .. filepath)
end

--- Open a settings file that matches the current buffer
M.open_buf_config = function()
  with_server_name(nil, function(server_name)
    if not server_name then
      return
    end

    M.open_config(server_name)
  end)
end

---Open the settings file for the specified server.
---@param server_name string
M.open_config = function(server_name)
  open(config.get().config_home, server_name)
end

---Open the settings file for the specified server.
---@param server_name string
M.open_local_config = function(server_name)
  local start_path = get_buffer_path()
  if start_path == '' then
    start_path = vim.fn.getcwd()
  end

  local conf = config.get()
  local root_dir
  if lspconfig[server_name] then
    root_dir = lspconfig[server_name].get_root_dir(path.sanitize(start_path))
  end

  if not root_dir then
    local markers = conf.local_settings_root_markers_fallback
    root_dir = lspconfig.util.root_pattern(markers)(path.sanitize(start_path))
  end

  if root_dir then
    open(path.join(root_dir:gsub('/$', ''), conf.local_settings_dir), server_name)
  else
    log.error(('[%s] Failed to get root_dir.'):format(server_name))
  end
end

--- Open a settings file that matches the current buffer
M.open_local_buf_config = function()
  with_server_name(nil, function(server_name)
    if not server_name then
      return
    end

    local clients = vim.tbl_filter(function(server)
      if server.name == server_name then
        return server
      end
    end, vim.lsp.buf_get_clients())
    local client = unpack(clients)

    if client then
      open(path.join(client.config.root_dir, config.get().local_settings_dir), server_name)
    else
      log.error(('[%s] Failed to get root_dir.'):format(server_name))
    end
  end)
end

---Update the setting values.
---@param server_name string
M.update_settings = function(server_name)
  vim.api.nvim_command 'redraw'

  if nlspsettings.update_settings(server_name) then
    log.error(('[%s] Failed to update the settings.'):format(server_name))
  else
    log.info(('[%s] Success to update the settings.'):format(server_name))
  end
end

---What to do when BufWritePost fires
---@param file string
M._BufWritePost = function(file)
  local server_name = path.sanitize(file):match '([^/]+)%.%w+$'
  M.update_settings(server_name)
end

---Executes command from action
---@param result nlspsettings.command.parser.result
---@param actions table
M._execute = function(result, actions)
  if actions[result.action] then
    actions[result.action](result.server)
  end
end

---Parses a command and executes it
---@vararg string
M._command = function(...)
  local result = parser.parse { ... }
  M._execute(result, {
    [parser.Actions.OPEN] = M.open_config,
    [parser.Actions.OPEN_BUFFER] = M.open_buf_config,
    [parser.Actions.OPEN_LOCAL] = M.open_local_config,
    [parser.Actions.OPEN_LOCAL_BUFFER] = M.open_local_buf_config,
    [parser.Actions.UPDATE] = M.update_settings,
  })
end

return M
