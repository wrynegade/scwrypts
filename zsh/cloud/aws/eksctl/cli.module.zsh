#####################################################################

use cloud/aws/zshparse/overrides

DEPENDENCIES+=(eksctl)

#####################################################################

${scwryptsmodule}() {
	local PARSERS=(cloud.aws.zshparse.overrides)
	local DESCRIPTION="
		Context wrapper for eksctl commands; prevents accidental local environment
		bleed-through, but otherwise works exactly like 'eksctl'.

		This wrapper should be used in place of _all_ 'eksctl' usages within scwrypts.
	"

	eval "$(utils.parse.autosetup)"

	##########################################

	echo.debug "invoking '$(echo "$AWS_EVAL_PREFIX" | sed 's/AWS_\(ACCESS_KEY_ID\|SECRET_ACCESS_KEY\)=[^ ]\+ //g')eksctl ${ARGS[@]}'"
	eval "${AWS_EVAL_PREFIX}eksctl ${ARGS[@]}"
}

#####################################################################

${scwryptsmodule}.parse() {
	return 0
}

${scwryptsmodule}.parse.locals() {
	local ARGS=()
}

${scwryptsmodule}.parse.usage() {
	USAGE__args+='
		args   all remaining arguments are forwarded to eksctl
	'
}
