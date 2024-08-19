#####################################################################

utils.is-macos() { uname -s | grep -q 'Darwin'; }

#####################################################################

utils.open() {
	local OPEN=''
	{
		command -v xdg-open && OPEN=xdg-open
		command -v open     && OPEN=open
	} >/dev/null 2>&1

	[ ! $OPEN ] && { echo.error 'unable to detect default open command (e.g. xdg-open)'; return 1 }
	$OPEN $@
}

utils.less() { less -R $@ </dev/tty >/dev/tty; }

utils.yq() {
	yq --version | grep -q mikefarah || {
		yq $@  # this is a different version from the preferred but throwing this in for compatibility
		return $?
	}

	yq eval '... comments=""' | yq $@
}
