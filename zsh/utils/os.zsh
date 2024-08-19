IS_MACOS() { uname -s | grep -q 'Darwin'; }

OPEN() {
	local OPEN=''
	{
		command -v xdg-open && OPEN=xdg-open
		command -v open     && OPEN=open
	} >/dev/null 2>&1

	[ ! $OPEN ] && { echo.error 'unable to detect default open command (e.g. xdg-open)'; return 1 }
	$OPEN $@
}
