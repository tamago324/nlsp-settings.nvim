local schemas = require 'nlspsettings.schemas'
local config = require 'nlspsettings.config'

---@class nlspsettings.command.parser.flag
---@field server boolean
---@field unique boolean

---@class nlspsettings.command.parser.FLAGS
---@field buffer nlspsettings.command.parser.flag
---@field local nlspsettings.command.parser.flag
---@field update nlspsettings.command.parser.flag
local FLAGS = {
  ['buffer'] = {
    server = false,
    unique = false,
  },
  ['local'] = {
    server = true,
    unique = false,
  },
  ['update'] = {
    server = true,
    unique = true,
  },
}

---@class nlspsettings.command.parser.ACTIONS
---@field OPEN string
---@field OPEN_BUFFER string
---@field OPEN_LOCAL string
---@field OPEN_LOCAL_BUFFER string
---@field UPDATE string
local ACTIONS = {
  OPEN = 'open',
  OPEN_BUFFER = 'open_buffer',
  OPEN_LOCAL = 'open_local',
  OPEN_LOCAL_BUFFER = 'open_local_buffer',
  UPDATE = 'update',
}

---@class nlspsettings.command.parser.ERRORS
---@field NOT_SERVER string
---@field NOT_FLAG string
---@field FLAG_REPEATED string
---@field NOT_ALLOWED string
---@field SERVER_REQUIRED string
---@field EMPTY string
local ERRORS = {
  NOT_SERVER = '`%s` is not a valid server',
  NOT_FLAG = '`%s` is not a valid flag',
  FLAG_REPEATED = '`%s` is repeated',
  NOT_ALLOWED = '`%s` does not allow `%s` flag',
  SERVER_REQUIRED = '`%s` requires a server',
  EMPTY = 'argument #%i is empty',
}

--- Creates a parser from list
---@param list table
---@param arg string
---@param err string
local from_list = function(list, arg, err)
  for _, item in ipairs(list) do
    if item == arg then
      return arg
    end
  end
  error(err:format(arg))
end

--- Parses a flag
---@param arg string
---@return string
local parse_flag = function(arg)
  return from_list(vim.tbl_keys(FLAGS), arg, ERRORS.NOT_FLAG)
end

--- Parses a server
---@param arg string
---@return string
local parse_server = function(arg)
  if config.get().open_strictly then
    return from_list(schemas.get_langserver_names(), arg, ERRORS.NOT_SERVER)
  end
  return arg
end

local M = {
  Flags = FLAGS,
  Actions = ACTIONS,
}

---@class nlspsettings.command.parser.result
---@field action string
---@field server string?

--- Parses a table or a string
---@param args table|string
---@return nlspsettings.command.parser.result?
M.parse = function(args)
  local flags = {}
  local context = {
    requires_server = true,
    unique_flag = nil,
    last_flag = nil,
  }

  if type(args) == 'string' then
    args = vim.split(args, ' ')
  end

  local function process_flag(flag)
    if flags[flag] then
      error(ERRORS.FLAG_REPEATED:format(flag))
    end

    if context.unique_flag then
      error(ERRORS.NOT_ALLOWED:format(context.unique_flag, flag))
    elseif FLAGS[flag].unique and context.last_flag then
      error(ERRORS.NOT_ALLOWED:format(context.last_flag, flag))
    end

    if not FLAGS[flag].server then
      context.requires_server = nil
    end

    flags[flag] = true
    context.unique_flag = FLAGS[flag].unique and flag
    context.last_flag = flag
  end

  if vim.tbl_isempty(args) then
    error(ERRORS.EMPTY:format(1))
  end

  for index, arg in ipairs(args) do
    if arg == '' then
      error(ERRORS.EMPTY:format(index))
    end

    if index == #args then
      local success, flag = pcall(parse_flag, arg)
      if success then
        process_flag(flag)
      elseif not context.requires_server then
        error(flag)
      end

      if success and context.requires_server and index == 1 then
        error(ERRORS.SERVER_REQUIRED:format(flag))
      end

      break
    end

    process_flag(parse_flag(arg))
  end

  local action = ACTIONS.OPEN
  if flags['local'] and flags['buffer'] then
    action = ACTIONS.OPEN_LOCAL_BUFFER
  elseif flags['local'] then
    action = ACTIONS.OPEN_LOCAL
  elseif flags['buffer'] then
    action = ACTIONS.OPEN_BUFFER
  elseif flags['update'] then
    action = ACTIONS.UPDATE
  end

  return {
    action = action,
    server = context.requires_server and parse_server(args[#args]),
  }
end

return M
