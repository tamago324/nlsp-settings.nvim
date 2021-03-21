if exists('g:loaded_nlspsettings')
  finish
endif
let g:loaded_nlspsettings = 1

command! NlspConfig lua require('nlspsettings.command').open_config()
command! NlspRealoadConfig lua require('nlspsettings.command').reload_config()

