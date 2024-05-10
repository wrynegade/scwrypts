${scwryptsmodule}() {
	local ERRORS=0
	[ $1 ] \
		|| echo.error "must specify a function name to provide" \
		|| return 2

	command -v $1 || echo.error "missing '$1'"
}
