local log = require 'nlspsettings.log'

---@param t table
---@return boolean
local is_table = function(t)
  return type(t) == 'table' and (not vim.tbl_islist(t) or vim.tbl_isempty(t))
end

--- * YAMLの場合、table のみ
---    { url: globpattern }
--- * JSON の場合、list のみ
---    { { fileMatch = string, url = string } }
--- もし、list + table や table + list のように渡されたらメッセージを表示して、t1 を返す
---@param t1 table
---@param t2 table
---@return table
local extend = function(t1, t2)
  -- 変えないようにする
  t1 = vim.deepcopy(t1)
  t2 = vim.deepcopy(t2)

  if vim.tbl_islist(t1) and vim.tbl_islist(t2) then
    -- list + list
    vim.list_extend(t1, t2)
    return t1
  end

  if is_table(t1) and is_table(t2) then
    -- table + table
    t1 = vim.tbl_deep_extend('keep', t1, t2)
    return t1
  end

  if (vim.tbl_islist(t1) and is_table(t2)) or (is_table(t1) and vim.tbl_islist(t2)) then
    -- list + table
    -- table + list
    log.warn('Cannot merge list and table', true)
  end
  return t1
end


--- Get active clients.
local get_clients = function()
  if vim.version().major == 0 and vim.version().minor <= 9 then
    -- DEPRECATED IN 0.10
    return vim.lsp.get_active_clients()
  else
    return vim.lsp.get_clients()
  end
end

return {
  extend = extend,
  get_clients = get_clients
}
