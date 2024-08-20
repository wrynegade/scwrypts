#####################################################################

use scwrypts/environment/common

use scwrypts/environment/get-full-template
use scwrypts/environment/get-envvar-lookup-map

use scwrypts/cache-output

#####################################################################

${scwryptsmodule}.get() {
	eval "$(usage.reset)"
	local USAGE__description="
		Generates a metadata-enriched environment YAML for the target environment.
	" \
		CACHE_ARGS=() \
		ENVIRONMENT_NAME \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			scwrypts.environment.user.zshparse.env-name
			)

	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.user.yaml \
		-- \
		scwrypts.environment.user.get.helper "$ENVIRONMENT_NAME" \
		;
}


${scwryptsmodule}.get-shell-values() {
	eval "$(usage.reset)"
	local USAGE__description="
		used primarily by utils.environment.check in scwrypts environments

		returns yaml which contains shell-compatible lookup values
		  - moving inherited .PARENTVALUE to value (if value is empty)
		  - moving inherited .PARENTSELECTION to selection (if selection is empty)
		  - converting list 'values' to shell-arrays
	" \
		CACHE_ARGS=() \
		ENVIRONMENT_NAME \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			scwrypts.environment.user.zshparse.env-name
			)

	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.shell.yaml \
		-- \
		_SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES \
			--environment-name "$ENVIRONMENT_NAME" \
		;
}

${scwryptsmodule}.get-json() {
	eval "$(usage.reset)"
	local USAGE__description="
		returns a JSON object containing live environment configurations
		for the target environment

		contains both .path.style.lookup path and ENVIRONMENT_VARIABLE lookup keys
	" \
		CACHE_ARGS=() \
		ENVIRONMENT_NAME \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			scwrypts.environment.user.zshparse.env-name
			)

	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.user.json \
		-- \
		scwrypts.environment.user.get-json.helper \
			--environment-name "$ENVIRONMENT_NAME" \
		;
}

#####################################################################

${scwryptsmodule}.zshparse.env-name() {
	# local ENVIRONMENT_NAME
	local PARSED=0
	case $1 in
		--environment-name )
			PARSED=2
			ENVIRONMENT_NAME=$2

			# bypass cache when specifying explicit environment name
			[[ ${(t)CACHE_ARGS} =~ array ]] && CACHE_ARGS+=(--use-cache bypass)
			;;
	esac
	return $PARSED
}

${scwryptsmodule}.zshparse.env-name.usage() {
	USAGE__options+="\n
		--environment-name <string>   name of a scwrypts environment (default: $SCWRYPTS_ENV)
		                              using this flag will bypass cache
	"
}

${scwryptsmodule}.zshparse.env-name.validate() {
	[ "$ENVIRONMENT_NAME" ] || ENVIRONMENT_NAME="$SCWRYPTS_ENV"
}

#####################################################################

${scwryptsmodule}.get.helper() {
	local ENVIRONMENT_NAME LOADING_ORIGINAL_ENV=true
	local _S ERRORS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			--parent ) LOADING_ORIGINAL_ENV=false
				;;
			* )
				: \
					&& [ ! $ENVIRONMENT_NAME ] \
					|| echo.error "unknown argument '$1'" \
					|| break

				[ $ENVIRONMENT_NAME ] || { ENVIRONMENT_NAME="$1"; break; }
		esac
		shift $_S
	done

	utils.check-errors --no-fail || return $?

	local ENVIRONMENT_NAME="$1"
	[ $ENVIRONMENT_NAME ] || ENVIRONMENT_NAME=$SCWRYPTS_ENV

	[[ $LOADING_ORIGINAL_ENV =~ true ]] && {
		case $SCWRYPTS_ENVIRONMENT__SHOW_ENV_HELP in
			true )
				echo "
					#
					# current scwrypts environment = $ENVIRONMENT_NAME
					#
					# - metadata tags are READONLY; changes to any key which starts with a
					#   '.' followed by all-caps (e.g. '.DESCRIPTION') will be ignored on
					#   save
					#
					# - value precedence is as follows (lower number is higher priority):
					#    0. runtime environment variable '__override' value
					#    1. the value from the 'value' key
					#    2. the value from the '.PARENTVALUE' (if 'value' key is null)
					#    3. a user-selected value from the 'selection' list
					#    4. a user-selected value from the '.PARENTSELECTION' list
					#
					# - values are used like environment variables, although most scalar
					#   values are permitted, they are converted to strings or string arrays
					#   before use; string 'null' is OK, but null-type means not configured
					#
					# - for 'value'     null-type / empty = not configured
					# - for 'selection' null-type / empty / empty-list = not configured
					#
					---
				"
				;;
			false )
				echo "---  # current scwrypts environment = $ENVIRONMENT_NAME"
				;;
		esac | sed 's/\(^\s\+\|\s\+$\)//g; /^$/d'
	}

	local GROUP GROUP_CONFIG_FILENAME
	{
		scwrypts.environment.user.get-full-template-with-value-keys
		[[ $LOADING_ORIGINAL_ENV =~ true ]] && {
			for PARENT in $(scwrypts.environment.common.get-parent-env-names "$ENVIRONMENT_NAME")
			do
				echo ---
				scwrypts.environment.user.get.helper --parent "$PARENT" \
					| sed '
						s/^\(\s\+\)\(value\|selection\):/\1.PARENT\U\2:/
						' \
					| utils.yq '.
						| del(.. | select(has(".PARENTVALUE") and .".PARENTVALUE" == null).".PARENTVALUE")
						| del(.. | select(has(".PARENTSELECTION") and (.".PARENTSELECTION" | length) == 0).".PARENTSELECTION")
						| del(.. | select(has(".PARENTSELECTION") and has(".PARENTVALUE")).".PARENTSELECTION")
						' \
					;
			done
		}
		for GROUP in ${SCWRYPTS_GROUPS[@]}
		do
			GROUP_CONFIG_FILENAME="$(scwrypts.environment.common.get-env-filename "$ENVIRONMENT_NAME" "$GROUP")"

			[ -f "${GROUP_CONFIG_FILENAME}" ] || touch "${GROUP_CONFIG_FILENAME}"

			[[ $(head -n1 "$GROUP_CONFIG_FILENAME") =~ ^---$ ]] || echo ---
			cat "$GROUP_CONFIG_FILENAME"
		done
	} \
		| scwrypts.environment.common.combine-template-files \
		| utils.yq -P \
		| sed -z 's/\n[a-z]/\n&/g' \
		| sed 's/value: null$/value:/; /\svalue:/G' \
		;
}

${scwryptsmodule}.get-full-template-with-value-keys() {
	scwrypts.environment.get-full-template \
		| utils.yq '(.. | select(has(".ENVIRONMENT"))) += {
				"selection": [],
				"value": null
			}
			' \
		| sed 's/ ""$//'
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES() {
	scwrypts.environment.user.get $@ \
		| utils.yq '..
			|= select(
				((has ("value") | not) or .value == null) and has (".PARENTVALUE")
				).value = .".PARENTVALUE"
			' \
		| utils.yq '..
			|= select(
				((has ("selection") | not) or .selection == null or .selection | length == 0) and has (".PARENTVALUE")
				).value = .".PARENTVALUE"
			' \
		| utils.yq '..
			|= select(
				has("value") and .value | type == "!!seq" and .value | length != 0
				).value = "(" + (.value | join " ") + ")"
			' \
		| utils.yq '.
			| del(.. | select(has(".PARENTVALUE")).".PARENTVALUE")
			| del(.. | select(has(".ENVIRONMENT")).".ENVIRONMENT")
			| del(.. | select(has(".GROUP")).".GROUP")
			| del(.. | select(has(".DESCRIPTION")).".DESCRIPTION")
			| del(.. | select(has("value") and .value == null).value)
			| del(.. | select(has("selection") and (.selection == null or .selection | length == 0)).selection)
			| del(.. | select(has("value") and has("selection")).selection)
			' \
			;
}

#####################################################################

${scwryptsmodule}.get-json.helper() {
	local SHELL_VALUES="$(_SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES $@)"
	local LOOKUP_MAP="$(scwrypts.environment.template.get-envvar-lookup-map)"
	{
		echo "$SHELL_VALUES"
		local ENVIRONMENT_VARIABLE
		for ENVIRONMENT_VARIABLE in $(\
			scwrypts.environment.get-full-template \
				| utils.yq '.. | select(has(".ENVIRONMENT")) | .".ENVIRONMENT"' \
			)
		do
			echo "$ENVIRONMENT_VARIABLE: $(echo "$SHELL_VALUES" | utils.yq -r "$(echo "$LOOKUP_MAP" | utils.yq -r ".$ENVIRONMENT_VARIABLE")")"
		done
	} | utils.yq -oj
}
