---@param t table
---@return boolean
local is_table = function(t)
  return type(t) == 'table' and not vim.tbl_islist(t)
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
    vim.notify_once('[Nlspsettings] Cannot merge list and table', vim.log.levels.WARN, {})
  end
  return t1
end

return {
  extend = extend,
}
