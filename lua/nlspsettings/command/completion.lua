local schemas = require 'nlspsettings.schemas'
local parser = require 'nlspsettings.command.parser'

--- Get the flags to implement in the completion
---@param cmdline string
---@return string[], boolean
local get_flags = function(cmdline)
  local result = {}
  local server = true
  local matched = false
  local unique

  for flag, data in pairs(parser.Flags) do
    if data.unique then
      unique = flag
    elseif cmdline:match(flag) then
      if not data.server then
        server = false
      end
      matched = true
    else
      table.insert(result, flag)
    end
  end

  if matched then
    return result, server
  elseif cmdline:match(unique) then
    return {}, server
  end

  return vim.tbl_keys(parser.Flags), server
end

--- Get the servers supported
---@param cmdline string
---@return string[], boolean
local get_servers = function(cmdline)
  local result = {}
  for _, server in ipairs(schemas.get_langserver_names()) do
    if cmdline:match(server) then
      return {}, true
    end
    table.insert(result, server)
  end
  return result, false
end

local M = {}

--- Returns the smarter completion list
---@param _ string
---@param cmdline string
---@return string
M.complete = function(_, cmdline)
  local items = {}
  local flags, requires_server = get_flags(cmdline)
  local servers, server_found = get_servers(cmdline)

  if server_found then
    return ''
  end

  if requires_server then
    vim.list_extend(items, servers)
  end

  vim.list_extend(items, flags)

  return table.concat(items, '\n')
end

return M
