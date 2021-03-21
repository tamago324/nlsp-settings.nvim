if exists('g:loaded_nlspsettings')
  finish
endif
let g:loaded_nlspsettings = 1

function! s:complete(arg, line, pos) abort
  return join(luaeval('require("nlspsettings.jsonls").get_langserver_names()'), "\n")
endfunction

command! -nargs=1 -complete=custom,s:complete NlspConfig lua require('nlspsettings.command').open_config(<f-args>)
command! NlspRealoadConfig lua require('nlspsettings.command').reload_config()

