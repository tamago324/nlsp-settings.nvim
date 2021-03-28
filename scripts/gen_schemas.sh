#!/bin/sh

exec nvim -u NONE -E -R --headless +'set rtp+=$PWD' +'set rtp+=$PWD/nvim-lspconfig' +'luafile scripts/gen_schemas.lua' +'luafile scripts/gen_schemas_readme.lua' +'q'
