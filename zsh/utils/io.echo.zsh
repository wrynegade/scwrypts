echo.success() {  # command completed successfully
	utils.io.print $@ --minimum-log-level 1 --prefix "echo.success  ✔" --color  $(utils.colors.green)
	return 0
}

echo.error() {  # command encountered an error
	utils.io.print $@ --minimum-log-level 1 --prefix "echo.error    ✖" --color  $(utils.colors.red)
	((ERRORS+=1))
	return $ERRORS
}

echo.reminder() {  # sysadmin reminder or important notice to users
	utils.io.print $@ --minimum-log-level 1 --prefix "echo.reminder " --color $(utils.colors.bright-magenta)
	return 0
}

echo.status() {  # general status updates (prefer this to generic 'echo')
	utils.io.print $@ --minimum-log-level 2 --prefix "echo.status    " --color  $(utils.colors.blue) 
	return 0
}

echo.warning() {  # warning-level messages; not errors
	utils.io.print $@ --minimum-log-level 3 --prefix "echo.warning  " --color  $(utils.colors.yellow) 
	return 0
}

echo.debug() {  # helpful during development or (sparingly) to help others' development
	utils.io.print $@ --minimum-log-level 4 --prefix "echo.debug    ℹ" --color $(utils.colors.white) \
		"\n  DEBUG::funcstack : ${funcstack[@]:1}" \
		;
	return 0
}
