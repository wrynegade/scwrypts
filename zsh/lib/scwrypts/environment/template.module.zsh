#####################################################################

use scwrypts/environment/common
use scwrypts/cache

#####################################################################

SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		Provies the combined YAML of all available scwrypts group 'template.yaml' files.

		Template is cached after first generation in a given scwrypts runtime.
	"

	local \
		CACHE_ARGS=() \
		PARSERS=(
			SCWRYPTS__CACHED_OUTPUT__ARGS
			)

	eval "$ZSHPARSEARGS"
	##########################################

	SCWRYPTS__CACHED_OUTPUT ${CACHE_ARGS[@]} \
		--cache-file environment.template.yaml \
		-- \
		_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE \
		;
}

SCWRYPTS_ENVIRONMENT__GET_ENVVAR_LOOKUP_MAP() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		outputs a JSON map which can be used to lookup config-file query
		paths from environment variable names; GET_FULL_TEMPLATE flags OK

		key   : environment variable name
		value : jq-style query path
	"

	local \
		PARSERS=(
			SCWRYPTS__CACHED_OUTPUT__ARGS  # passthrough
			)

	eval "$ZSHPARSEARGS"
	##########################################
	SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE $@ \
		| YQ -P '
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
		GROUP_ROOT="$(eval echo '$SCWRYPTS_ROOT__'$GROUP)"

		GROUP_TEMPLATE_FILENAME="$GROUP_ROOT/.config/env.yaml"

		[ -f "$GROUP_TEMPLATE_FILENAME" ] && {
			[[ $(head -n1 "$GROUP_TEMPLATE_FILENAME") =~ ^---$ ]] || echo ---
				cat "$GROUP_TEMPLATE_FILENAME" \
					| YQ "(.. | select(has(\".ENVIRONMENT\"))) += {\".GROUP\":\"$GROUP\"}"
		}
	done
	} | _SCWRYPTS_ENVIRONMENT__COMBINE_TEMPLATE_FILES
}
