#
# send notifications from the command line
#

SCWRYPTS_NOTIFICATION_ENGINES=(echo)
#
# a "notification engine" implements all the .methods in the first block
# of ../utils/io/20-echo.zsh (e.g. "echo.success")
#
# using 'echo' as a notification engine will print the message to the
# console as well
#
# overwrite this variable if you only want to notify a subset of engines
# e.g. :
#   local SCWRYPTS_NOTIFICATION_ENGINES=(echo desktop)
#

# notify-send integration
use notify/desktop

#####################################################################

${scwryptsmodule}() {  # notify all available methods
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
