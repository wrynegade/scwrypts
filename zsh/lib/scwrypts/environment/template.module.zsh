#####################################################################

use scwrypts/environment/common

#####################################################################


__SCWRYPTS_ENVIRONMENT_CACHE__TEMPLATE="$SCWRYPTS_TEMP_PATH/environment.template.yaml"
rm -- "$__SCWRYPTS_ENVIRONMENT_CACHE__TEMPLATE" &>/dev/null

SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE() {
	local RESET_CACHED_TEMPLATE=false

	local _S ERRORS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			--reset-cache ) RESET_CACHED_TEMPLATE=true ;;
		esac
		shift $_S
	done

	CHECK_ERRORS --no-fail || return $?

	[[ $RESET_CACHED_TEMPLATE =~ true ]] \
		&& rm -- "$__SCWRYPTS_ENVIRONMENT_CACHE__TEMPLATE" &>/dev/null

	[ -f "$__SCWRYPTS_ENVIRONMENT_CACHE__TEMPLATE" ] || {
		_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE > "$__SCWRYPTS_ENVIRONMENT_CACHE__TEMPLATE"
	}

	cat "$__SCWRYPTS_ENVIRONMENT_CACHE__TEMPLATE"
}

SCWRYPTS_ENVIRONMENT__GET_ENVVAR_LOOKUP_MAP() {
	# outputs a JSON map which can be used to lookup config-file query
	# paths from environment variable names; GET_FULL_TEMPLATE flags OK
	#
	# key   : environment variable name
	# value : jq-style query path
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
