.PHONY: fmt
fmt:
	stylua --config-path stylua.toml --glob 'lua/**/*.lua' --glob '!**/deps/**/**.lua' -- lua
