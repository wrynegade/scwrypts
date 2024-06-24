#####################################################################

DEPENDENCIES+=(aws)

use cloud/aws/zshparse

#####################################################################

AWS() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		Safe context wrapper for aws cli commands; prevents accidental local environment
		bleed-through, but otherwise works exactly like 'aws'. For help with awscli, try
		'AWS [command] help' (no -h or --help)

		This wrapper should be used in place of _all_ 'aws' usages within scwrypts.
	"

	USAGE__args+='
		args   arguments forwarded to the AWS CLI
	'

	local \
		ACCOUNT AWS_EVAL_PREFIX AWS_CONTEXT_ARGS=() \
		ARGS=() ARGS_FORCE=allowed \
		PARSERS=(
			AWS_PARSER__OVERRIDES
		)

	eval "$ZSHPARSEARGS"

	##########################################

	DEBUG "invoking 'AWS_ACCOUNT=$ACCOUNT aws ${AWS_CONTEXT_ARGS[@]} ${ARGS[@]}'"
	eval "${AWS_EVAL_PREFIX}aws ${AWS_CONTEXT_ARGS[@]} ${ARGS[@]}"
}
