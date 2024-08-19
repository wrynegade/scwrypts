#####################################################################

use scwrypts/environment/common

use scwrypts/environment/template
use scwrypts/cache-output

#####################################################################

SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT() {
	eval "$(USAGE.reset)"
	local USAGE__description="
		Generates a metadata-enriched environment YAML for the target environment.
	" \
		CACHE_ARGS=() \
		ENVIRONMENT_NAME \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			SCWRYPTS_ENVIRONMENT__PARSE_ENV_NAME
			)

	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.user.yaml \
		-- \
		_SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT "$ENVIRONMENT_NAME" \
		;
}


SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_SHELL_VALUES() {
	eval "$(USAGE.reset)"
	local USAGE__description="
		used primarily by __CHECK_ENV_VAR in scwrypts environments

		returns yaml which contains shell-compatible lookup values
		  - moving inherited .PARENTVALUE to value (if value is empty)
		  - moving inherited .PARENTSELECTION to selection (if selection is empty)
		  - converting list 'values' to shell-arrays
	" \
		CACHE_ARGS=() \
		ENVIRONMENT_NAME \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			SCWRYPTS_ENVIRONMENT__PARSE_ENV_NAME
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

SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_JSON() {
	eval "$(USAGE.reset)"
	local USAGE__description="
		returns a JSON object containing live environment configurations
		for the target environment

		contains both .path.style.lookup path and ENVIRONMENT_VARIABLE lookup keys
	" \
		CACHE_ARGS=() \
		ENVIRONMENT_NAME \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			SCWRYPTS_ENVIRONMENT__PARSE_ENV_NAME
			)

	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.user.json \
		-- \
		_SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_JSON \
			--environment-name "$ENVIRONMENT_NAME" \
		;
}

#####################################################################

SCWRYPTS_ENVIRONMENT__PARSE_ENV_NAME() {
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

SCWRYPTS_ENVIRONMENT__PARSE_ENV_NAME.usage() {
	USAGE__options+="\n
		--environment-name <string>   name of a scwrypts environment (default: $SCWRYPTS_ENV)
		                              using this flag will bypass cache
	"
}

SCWRYPTS_ENVIRONMENT__PARSE_ENV_NAME.validate() {
	[ "$ENVIRONMENT_NAME" ] || ENVIRONMENT_NAME="$SCWRYPTS_ENV"
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT() {
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

	CHECK_ERRORS --no-fail || return $?

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
		_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE_WITH_VALUE_KEYS
		[[ $LOADING_ORIGINAL_ENV =~ true ]] && {
			for PARENT in $(_SCWRYPTS_ENVIRONMENT__GET_PARENT_ENV_NAMES "$ENVIRONMENT_NAME")
			do
				echo ---
				_SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT --parent "$PARENT" \
					| sed '
						s/^\(\s\+\)\(value\|selection\):/\1.PARENT\U\2:/
						' \
					| YQ '.
						| del(.. | select(has(".PARENTVALUE") and .".PARENTVALUE" == null).".PARENTVALUE")
						| del(.. | select(has(".PARENTSELECTION") and (.".PARENTSELECTION" | length) == 0).".PARENTSELECTION")
						| del(.. | select(has(".PARENTSELECTION") and has(".PARENTVALUE")).".PARENTSELECTION")
						' \
					;
			done
		}
		for GROUP in ${SCWRYPTS_GROUPS[@]}
		do
			GROUP_CONFIG_FILENAME="$(SCWRYPTS_ENVIRONMENT__GET_ENV_FILE_NAME "$ENVIRONMENT_NAME" "$GROUP")"

			[ -f "${GROUP_CONFIG_FILENAME}" ] || touch "${GROUP_CONFIG_FILENAME}"

			[[ $(head -n1 "$GROUP_CONFIG_FILENAME") =~ ^---$ ]] || echo ---
			cat "$GROUP_CONFIG_FILENAME"
		done
	} \
		| _SCWRYPTS_ENVIRONMENT__COMBINE_TEMPLATE_FILES \
		| YQ -P \
		| sed -z 's/\n[a-z]/\n&/g' \
		| sed 's/value: null$/value:/; /\svalue:/G' \
		;
}

_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE_WITH_VALUE_KEYS() {
	SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE \
		| YQ '(.. | select(has(".ENVIRONMENT"))) += {
				"selection": [],
				"value": null
			}
			' \
		| sed 's/ ""$//'
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES() {
	SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT $@ \
		| YQ '..
			|= select(
				((has ("value") | not) or .value == null) and has (".PARENTVALUE")
				).value = .".PARENTVALUE"
			' \
		| YQ '..
			|= select(
				((has ("selection") | not) or .selection == null or .selection | length == 0) and has (".PARENTVALUE")
				).value = .".PARENTVALUE"
			' \
		| YQ '..
			|= select(
				has("value") and .value | type == "!!seq" and .value | length != 0
				).value = "(" + (.value | join " ") + ")"
			' \
		| YQ '.
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

_SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_JSON() {
	local SHELL_VALUES="$(_SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES $@)"
	local LOOKUP_MAP="$(SCWRYPTS_ENVIRONMENT__GET_ENVVAR_LOOKUP_MAP)"
	{
		echo "$SHELL_VALUES"
		local ENVIRONMENT_VARIABLE
		for ENVIRONMENT_VARIABLE in $(\
			SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE \
				| YQ '.. | select(has(".ENVIRONMENT")) | .".ENVIRONMENT"' \
			)
		do
			echo "$ENVIRONMENT_VARIABLE: $(echo "$SHELL_VALUES" | YQ -r "$(echo "$LOOKUP_MAP" | YQ -r ".$ENVIRONMENT_VARIABLE")")"
		done
	} | YQ -oj
}
