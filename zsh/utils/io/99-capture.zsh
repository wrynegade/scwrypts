utils.io.capture() {
	local USAGE="
		usage: stdout-varname stderr-varname [...cmd and args...]

		captures stdout and stderr on separate variables for a command
	"
	{
		IFS=$'\n' read -r -d '' $2;
		IFS=$'\n' read -r -d '' $1;
	} < <((printf '\0%s\0' "$(${@:3})" 1>&2) 2>&1)
}
