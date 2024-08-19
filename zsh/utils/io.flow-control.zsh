#####################################################################

utils.fail()  {  # displays a crash error and exit
	echo.error --force-print ${@:2}
	exit $1
}

utils.abort() {  # for consistency; use after user aborts REQUIRED input
	utils.fail 69 'user abort'
}

#####################################################################

utils.check-errors() {  # aborts if 'echo.error' was ever called
	[ ${ERRORS} ] && [[ ${ERRORS} -ne 0 ]] || return 0

	local DISPLAY_USAGE=true
	local FAIL_OUT=true

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--no-usage ) DISPLAY_USAGE=false ;;
			--no-fail  ) FAIL_OUT=false ;;
		esac
		shift 1
	done

	[[ ${DISPLAY_USAGE} =~ true ]] && utils.io.usage

	[[ ${FAIL_OUT} =~ true ]] && exit ${ERRORS} || return ${ERRORS}
}

#####################################################################

utils.io.capture() {
	local USAGE="
		usage: stdout-varname stderr-varname [...cmd and args...]

		captures stdout and stderr on separate variables for a command
	"
	{
		IFS=$'\n' read -r -d '' $2;
		IFS=$'\n' read -r -d '' $1;
	} < <((printf '\0%s\0' "$(${@:3})" 1>&2) 2>&1)
}
