echo.success.color() { utils.colors.green; }
echo.success() {  # command completed successfully
	utils.io.print $@ --minimum-log-level 1 --prefix "SUCCESS  ✔" --color  $(echo.success.color)
	return 0
}

echo.error.color() { utils.colors.red; }
echo.error() {  # command encountered an error
	utils.io.print $@ --minimum-log-level 1 --prefix "ERROR    ✖" --color  $(echo.error.color)
	((ERRORS+=1))
	return ${ERRORS}
}

echo.reminder.color() { utils.colors.bright-magenta; }
echo.reminder() {  # sysadmin reminder or important notice to users
	utils.io.print $@ --minimum-log-level 1 --prefix "REMINDER " --color $(echo.reminder.color)
	return 0
}

echo.status.color() { utils.colors.blue; }
echo.status() {  # general status updates (prefer this to generic 'echo')
	utils.io.print $@ --minimum-log-level 2 --prefix "STATUS    " --color  $(echo.status.color)
	return 0
}

echo.warning.color() { utils.colors.yellow; }
echo.warning() {  # warning-level messages; not errors
	utils.io.print $@ --minimum-log-level 3 --prefix "WARNING  " --color  $(echo.warning.color)
	return 0
}

echo.debug.color() { utils.colors.white; }
echo.debug() {  # helpful during development or (sparingly) to help others' development
	# early exit since debug injects state information
	[ ${SCWRYPTS_LOG_LEVEL} ] && [[ ${SCWRYPTS_LOG_LEVEL} -lt 4 ]] && [[ ! $@ =~ --force-print ]] && return 0

	utils.io.print $@ --minimum-log-level 4 --prefix "DEBUG    ℹ" --color $(echo.debug.color) \
		"\n> DEBUG::funcstack : $(echo "${funcstack[@]:1}" | sed 's/ (anon) (eval) (anon)$/ scwrypts/')" \
		"\n> DEBUG::timestamp : $(date +%s)" \
		;
	return 0
}

#####################################################################

echo.prompt() {
	[ ! "${SCWRYPTS_LOG_LEVEL}" ] && local SCWRYPTS_LOG_LEVEL=4

	[[ "${SCWRYPTS_LOG_LEVEL}" -eq 0 ]] && {
		utils.io.print --format raw $@ ": " --no-line-end
		return 0
	}

	utils.io.print $@ --prefix "PROMPT   " --color $(utils.colors.cyan)
	utils.io.print '' --prefix "USER     ⌨" --color $(utils.colors.bright-cyan) --no-line-end
	return 0
}
