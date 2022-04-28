__IS_MACOS() { uname -s | grep -q 'Darwin'; }

__OPEN() {
	local OPEN=''
	{
		command -v xdg-open && OPEN=xdg-open
		command -v open     && OPEN=open
	} >/dev/null 2>&1

	[ ! $OPEN ] && { __ERROR 'unable to detect default open command (e.g. xdg-open)'; return 1 }
	$OPEN $@
}
