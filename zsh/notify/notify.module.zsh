#
# send notifications from the command line
#

# a "notification engine" implements all the .methods in the first block
# of ../utils/io/20-echo.zsh (e.g. "echo.success")
SCWRYPTS_NOTIFICATION_ENGINES=(echo)

# notify-send integration
use notify/desktop


#####################################################################

${scwryptsmodule}() {  # print to console and notify all available methods
	local ENGINE
	for ENGINE in ${SCWRYPTS_NOTIFICATION_ENGINES[@]}
	do
		${ENGINE}.${1} ${@:2}
	done
	return 0
}

${scwryptsmodule}.success()  { notify success  $@; }
${scwryptsmodule}.error()    { notify error    $@; return 1; }
${scwryptsmodule}.reminder() { notify reminder $@; }
${scwryptsmodule}.status()   { notify status   $@; }
${scwryptsmodule}.warning()  { notify warning  $@; }
${scwryptsmodule}.debug()    { notify debug    $@; }
