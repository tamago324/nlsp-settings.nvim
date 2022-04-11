if exists('g:loaded_nlspsettings')
  finish
endif
let g:loaded_nlspsettings = 1

command! -nargs=* -complete=custom,v:lua.require'nlspsettings.command.completion'.complete
            \ LspSettings lua require("nlspsettings.command")._command(<f-args>)

" deprecated
function! s:complete(arg, line, pos) abort
  return join(luaeval('require("nlspsettings.schemas").get_langserver_names()'), "\n")
endfunction

command! -nargs=1 -complete=custom,s:complete NlspConfig lua require('nlspsettings.deprecated').open()
command! -nargs=1 -complete=custom,s:complete NlspLocalConfig lua require('nlspsettings.deprecated').open_local()
command! -nargs=0 NlspBufConfig lua require('nlspsettings.deprecated').open_buffer()
command! -nargs=0 NlspLocalBufConfig lua require('nlspsettings.deprecated').open_local_buffer()
command! -nargs=1 -complete=custom,s:complete NlspUpdateSettings lua require('nlspsettings.deprecated').update()
