echo.success() {  # command completed successfully
	utils.io.print $@ --minimum-log-level 1 --prefix "SUCCESS  ✔" --color  $(utils.colors.green)
	return 0
}

echo.error() {  # command encountered an error
	utils.io.print $@ --minimum-log-level 1 --prefix "ERROR    ✖" --color  $(utils.colors.red)
	((ERRORS+=1))
	return ${ERRORS}
}

echo.reminder() {  # sysadmin reminder or important notice to users
	utils.io.print $@ --minimum-log-level 1 --prefix "REMINDER " --color $(utils.colors.bright-magenta)
	return 0
}

echo.status() {  # general status updates (prefer this to generic 'echo')
	utils.io.print $@ --minimum-log-level 2 --prefix "STATUS    " --color  $(utils.colors.blue) 
	return 0
}

echo.warning() {  # warning-level messages; not errors
	utils.io.print $@ --minimum-log-level 3 --prefix "WARNING  " --color  $(utils.colors.yellow) 
	return 0
}

echo.debug() {  # helpful during development or (sparingly) to help others' development
	utils.io.print $@ --minimum-log-level 4 --prefix "DEBUG    ℹ" --color $(utils.colors.white) \
		"\n  DEBUG::funcstack : ${funcstack[@]:1}" \
		;
	return 0
}

#####################################################################

echo.prompt() {
	[ ! "${SCWRYPTS_LOG_LEVEL}" ] && local SCWRYPTS_LOG_LEVEL=4

	[[ "${SCWRYPTS_LOG_LEVEL}" -eq 0 ]] && {
		utils.io.print --format raw $@ " : " --no-line-end
		return 0
	}

	utils.io.print $@ --prefix "PROMPT   " --color $(utils.colors.cyan)
	utils.io.print '' --prefix "USER     ⌨" --color $(utils.colors.bright-cyan) --no-line-end
	return 0
}
