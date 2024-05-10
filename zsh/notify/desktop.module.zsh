#####################################################################

SCWRYPTS_NOTIFICATION_ENGINES+=(${scwryptsmodule})

${scwryptsmodule}.success()  { notify.desktop echo.success  $@; }
${scwryptsmodule}.error()    { notify.desktop echo.error    $@; }
${scwryptsmodule}.reminder() { notify.desktop echo.reminder $@; }
${scwryptsmodule}.status()   { notify.desktop echo.status   $@; }
${scwryptsmodule}.warning()  { notify.desktop echo.warning  $@; }
${scwryptsmodule}.debug()    { notify.desktop echo.debug    $@; }

${scwryptsmodule}() {
	local MESSAGE="$($1 --stdout ${@:2} | utils.colors.remove)"
	[ "${MESSAGE}" ] && utils.notify-send "${MESSAGE}"
}
