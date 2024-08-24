#####################################################################

DEPENDENCIES+=(aws)

use cloud/aws/zshparse

#####################################################################

${scwryptsmodule}() {
	local PARSERS=(cloud.aws.zshparse.overrides)
	local ARGS=()
	local DESCRIPTION="
		Safe context wrapper for aws cli commands; prevents accidental local environment
		bleed-through, but otherwise works exactly like 'aws'. For help with awscli, try
		'AWS [command] help' (no -h or --help)

		This wrapper should be used in place of _all_ 'aws' usages within scwrypts.
		"

	eval "$(utils.parse.autosetup)"

	##########################################

	echo.debug "invoking '$(echo "$AWS_EVAL_PREFIX" | sed 's/AWS_\(ACCESS_KEY_ID\|SECRET_ACCESS_KEY\)=[^ ]\+ //g')aws ${AWS_CONTEXT_ARGS[@]} ${ARGS[@]}'"
	eval "${AWS_EVAL_PREFIX}aws ${AWS_CONTEXT_ARGS[@]} ${ARGS[@]}"
}

#####################################################################

${scwryptsmodule}.parse() {
	return 0  # uses default args parser
}

${scwryptsmodule}.parse.usage() {
	USAGE__args+='\$@   arguments forwarded to the AWS CLI'
}
