#####################################################################

use cloud/aws/eks

#####################################################################

EKSCTL() {
	eval "$(usage.reset)"
	local USAGE__description="
		Context wrapper for eksctl commands; prevents accidental local environment
		bleed-through, but otherwise works exactly like 'eksctl'.

		This wrapper should be used in place of _all_ 'eksctl' usages within scwrypts.
	"

	USAGE__args+='
		args   all remaining arguments are forwarded to eksctl
	'

	local \
		AWS_EVAL_PREFIX \
		ARGS=() ARGS_FORCE=allowed \

		PARSERS=(
			AWS_PARSER__OVERRIDES
		)

	eval "$ZSHPARSEARGS"

	##########################################

	echo.debug "invoking '$(echo "$AWS_EVAL_PREFIX" | sed 's/AWS_\(ACCESS_KEY_ID\|SECRET_ACCESS_KEY\)=[^ ]\+ //g')eksctl ${ARGS[@]}'"
	eval "${AWS_EVAL_PREFIX}eksctl ${ARGS[@]}"
}
