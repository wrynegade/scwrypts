${scwryptsmodule}() {
	local ERRORS=0
	[ $1 ] \
		|| ERROR "must specify a function name to provide" \
		|| return 2

	command -v $1 || ERROR "missing '$1'"
}
