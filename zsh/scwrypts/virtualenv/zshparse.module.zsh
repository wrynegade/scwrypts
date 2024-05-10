#####################################################################

${scwryptsmodule}.type-arg() {
	# local TYPE ARGS=()   # relies on default "args" parser
	return 0
}

${scwryptsmodule}.type-arg.usage() {
	USAGE__args="
		\$1   virtual environment type (one of ${SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS[@]})
	"
}

${scwryptsmodule}.type-arg.validate() {
	TYPE="${ARGS[1]}"

	[[ ${#ARGS} -gt 1 ]] \
		&& echo.error "too many arguments"

	[ "${TYPE}" ] \
		|| echo.error "must specify virtualenv type"
}

#####################################################################
