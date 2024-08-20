#####################################################################

use scwrypts/cache-output
use scwrypts/environment/get-full-template

#####################################################################

${scwryptsmodule}() {
	eval "$(usage.reset)"
	local USAGE__description="
		outputs a JSON map which can be used to lookup config-file query
		paths from environment variable names; GET_FULL_TEMPLATE flags OK

		key   : environment variable name
		value : jq-style query path
	"

	local \
		PARSERS=(
			scwrypts.cache-output.zshparse.args  # passthrough
			)

	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.environment.get-full-template $@ \
		| utils.yq -P '
			..
				| select(. == "*") 
				| {(.): "." + (path | join(".") + ".value")}
			'\
		| sed -n 's/\.\.ENVIRONMENT//p' \
		;
}
