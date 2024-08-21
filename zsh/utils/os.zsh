#####################################################################

utils.os.is-macos() { uname -s | grep -q 'Darwin'; }

#####################################################################

utils.open() {
	local OPEN
	for OPEN in \
		xdg-open \
		open \
		;
	do
		command -v ${OPEN} &>/dev/null && break
		OPEN=
	done

	[ ${OPEN} ] \
		|| echo.error 'unable to detect default open command (e.g. xdg-open)' \
		|| return 1 \
		;

	$OPEN $@
}
