local config = require 'nlspsettings.config'
local nlspsettings = require 'nlspsettings'
local lspconfig = require 'lspconfig'
local notify = vim.F.npcall(require, 'notify')

local path = lspconfig.util.path
local uv = vim.loop

local M = {}

--- Logs a message with the given log level.
---@param message string
---@param level number
local log = function(message, level)
  local title = 'NLsp Settings'
  local notify_config = config.get 'nvim_notify'

  if notify and notify_config and notify_config.enable then
    notify(message, level, {
      title = title,
      timeout = notify_config.timeout,
    })
  else
    vim.notify(('[%s] %s'):format(title, message), level)
  end
end

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
    if not vim.tbl_contains(server_names, _client.name) then
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
local open_config = function(dir, server_name)
  vim.validate {
    server_name = { server_name, 's' },
    dir = { dir, 's' },
  }

  if not path.is_dir(dir) then
    local prompt = ('Config directory "%s" not exists, create?'):format(path.sanitize(dir))

    if vim.fn.confirm(prompt, '&Yes\n&No', 1) ~= 1 then
      return
    end

    uv.fs_mkdir(dir, 420)
  end

  local loader = require('nlspsettings.loaders.' .. config.get 'loader')
  local filepath = path.join(dir, server_name .. '.' .. loader.file_ext)

  -- If the file does not exist, LSP will not be able to complete it, so create it
  if not path.is_file(filepath) then
    local fd = uv.fs_open(filepath, 'w', 420)

    if not fd then
      log('Could not create file: ' .. filepath, vim.log.levels.ERROR)
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
  open_config(config.get 'config_home', server_name)
end

---Open the settings file for the specified server.
---@param server_name string
M.open_local_config = function(server_name)
  local start_path = get_buffer_path()
  if start_path == '' then
    start_path = vim.fn.getcwd()
  end

  local markers = config.get 'local_settings_root_markers'
  local root_dir = lspconfig.util.root_pattern(markers)(path.sanitize(start_path))

  if root_dir then
    open_config(path.join(root_dir:gsub('/$', ''), config.get 'local_settings_dir'), server_name)
  else
    log(('[%s] Failed to get root_dir.'):format(server_name), vim.log.levels.ERROR)
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
      open_config(path.join(client.config.root_dir, config.get 'local_settings_dir'), server_name)
    else
      log(('[%s] Failed to get root_dir.'):format(server_name), vim.log.levels.ERROR)
    end
  end)
end

---Update the setting values.
---@param server_name string
M.update_settings = function(server_name)
  vim.api.nvim_command 'redraw'

  if nlspsettings.update_settings(server_name) then
    log(('[%s] Failed to update the settings.'):format(server_name), vim.log.levels.ERROR)
  else
    log(('[%s] Success to update the settings.'):format(server_name), vim.log.levels.INFO)
  end
end

---What to do when BufWritePost fires
---@param afile string
M._BufWritePost = function(afile)
  local server_name = path.sanitize(afile):match '([^/]+)%.%w+$'
  M.update_settings(server_name)
end

return M
