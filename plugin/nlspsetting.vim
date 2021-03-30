if exists('g:loaded_nlspsettings')
  finish
endif
let g:loaded_nlspsettings = 1

function! s:complete(arg, line, pos) abort
  return join(luaeval('require("nlspsettings.jsonls").get_langserver_names()'), "\n")
endfunction

command! -nargs=1 -complete=custom,s:complete NlspConfig lua require('nlspsettings.command').open_config(<f-args>)
command! -nargs=1 -complete=custom,s:complete NlspUpdateSettings lua require('nlspsettings.command').update_settings(<f-args>)
command! -nargs=0 NlspBufConfig lua require('nlspsettings.command').open_buf_config()

nnoremap <Plug>(nlsp-buf-config) <Cmd>lua require('nlspsettings.command').open_buf_config()<CR>

