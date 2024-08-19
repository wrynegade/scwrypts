#####################################################################

use scwrypts/environment/common

use scwrypts/cache-output

#####################################################################

SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE() {
	eval "$(usage.reset)"
	local USAGE__description="
		Provies the combined YAML of all available scwrypts group 'template.yaml' files.

		Template is cached after first generation in a given scwrypts runtime.
	"

	local \
		CACHE_ARGS=() \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			)

	eval "$ZSHPARSEARGS"
	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.template.yaml \
		-- \
		_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE \
		;
}

SCWRYPTS_ENVIRONMENT__GET_ENVVAR_LOOKUP_MAP() {
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
	SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE $@ \
		| utils.yq -P '
			..
				| select(. == "*") 
				| {(.): "." + (path | join(".") + ".value")}
			'\
		| sed -n 's/\.\.ENVIRONMENT//p' \
		;
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE() {
	local GROUP GROUP_ROOT GROUP_TEMPLATE_FILENAME
	{
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		GROUP_ROOT="$(scwrypts.config.group ${GROUP} root)"

		GROUP_TEMPLATE_FILENAME="$GROUP_ROOT/.config/env.yaml"

		[ -f "$GROUP_TEMPLATE_FILENAME" ] && {
			[[ $(head -n1 "$GROUP_TEMPLATE_FILENAME") =~ ^---$ ]] || echo ---
				cat "$GROUP_TEMPLATE_FILENAME" \
					| utils.yq "(.. | select(has(\".ENVIRONMENT\"))) += {\".GROUP\":\"$GROUP\"}"
		}
	done
	} | _SCWRYPTS_ENVIRONMENT__COMBINE_TEMPLATE_FILES
}
