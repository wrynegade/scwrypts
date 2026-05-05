#####################################################################

use scwrypts/environment/get-full-template

#####################################################################

${scwryptsmodule}() {
	local ARGS=() ARGS_FORCE=true
	local DESCRIPTION="
		outputs a JSON map which can be used to lookup config-file query
		paths from environment variable names; GET_FULL_TEMPLATE flags OK

		key   : environment variable name
		value : jq-style query path
	"

	eval "$(utils.parse.autosetup)"

	##########################################

	scwrypts.environment.get-full-template "${ARGS[@]}" \
		| utils.yq -P '
			..
				| select(. == "*")
				| {(.): "." + (path | join("."))}
			'\
		| sed -n 's/\.\.ENVIRONMENT//p' \
		;
}
