#####################################################################

DEPENDENCIES+=(aws)

use cloud/aws/zshparse
use cloud/aws/zshparse/cli

#####################################################################

AWS() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		Safe context wrapper for aws cli commands; prevents accidental local environment
		bleed-through, but otherwise works exactly like 'aws'. For help with awscli, try
		'AWS [command] help' (no -h or --help)

		This wrapper should be used in place of _all_ 'aws' usages within scwrypts.
	"

	local \
		ACCOUNT AWS_EVAL_PREFIX AWS_CONTEXT_ARGS=() \
		ARGS=() \
		PARSERS=(
			AWS_PARSER__OVERRIDES
			ARGS_PARSER__AWS
		)

	eval "$ZSHPARSEARGS"

	##########################################

	DEBUG "invoking 'AWS_ACCOUNT=$ACCOUNT aws ${AWS_CONTEXT_ARGS[@]} ${ARGS[@]}'"
	eval "${AWS_EVAL_PREFIX}aws ${AWS_CONTEXT_ARGS[@]} ${ARGS[@]}"
}
