#####################################################################

use scwrypts/environment/common

use scwrypts/environment/template

#####################################################################

__SCWRYPTS_ENVIRONMENT_CACHE__USER="$SCWRYPTS_TEMP_PATH/environment.user.yaml"
__SCWRYPTS_ENVIRONMENT_CACHE__SHELL="$SCWRYPTS_TEMP_PATH/environment.shell.yaml"
rm -- "$__SCWRYPTS_ENVIRONMENT_CACHE__USER" "$__SCWRYPTS_ENVIRONMENT_CACHE__SHELL" &>/dev/null

SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT() {
	local RESET_CACHED_TEMPLATE=false

	local ENVIRONMENT_NAME=$SCWRYPTS_ENV
	local MODE=cached-default

	local _S ERRORS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			--reset-cache ) RESET_CACHED_TEMPLATE=true ;;
			--environment-name )  # does not use cache
				[ $2 ] && ((_S+=1)) || ERROR 'missing environment name' || break
				MODE=specific-environment
				ENVIRONMENT_NAME="$2"
				;;
		esac
		shift $_S
	done

	CHECK_ERRORS --no-fail || return $?

	case $MODE in
		cached-default )
			[[ $RESET_CACHED_TEMPLATE =~ true ]] \
				&& rm "$__SCWRYPTS_ENVIRONMENT_CACHE__USER" &>/dev/null

			[ -f "$__SCWRYPTS_ENVIRONMENT_CACHE__USER" ] \
				|| _SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT > "$__SCWRYPTS_ENVIRONMENT_CACHE__USER"

			cat "$__SCWRYPTS_ENVIRONMENT_CACHE__USER"
			;;

		specific-environment )
			[[ $RESET_CACHED_TEMPLATE =~ true ]] \
				&& WARNING 'using --environment-name will never use cached template; no need for --reset-cache'

			_SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT "$ENVIRONMENT_NAME"
			;;
	esac

}

export __SCWRYPTS_ENVIRONMENT__USER_ENVIRONMENT_SHELL_VALUES=
SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_SHELL_VALUES() {
	# used primarily by __CHECK_ENV_VAR in scwrypts environments
	#
	# returns the shell-compatible user environment by
	#	- moving inherited .PARENTVALUE to value (if value is empty)
	#	- moving inherited .PARENTSELECTION to selection (if selection is empty)
	#	- converting list 'values' to shell-arrays
	local RESET_CACHED_TEMPLATE=false

	local ENVIRONMENT_NAME=$SCWRYPTS_ENV
	local MODE=cached-default

	local _S ERRORS=0
	local PASSTHROUGH_ARGS=($@)
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			--reset-cache ) RESET_CACHED_TEMPLATE=true ;;
			--environment-name )  # does not use cache
				[ $2 ] && ((_S+=1)) || ERROR 'missing environment name' || break
				MODE=specific-environment
				ENVIRONMENT_NAME="$2"
				;;
		esac
		shift $_S
	done

	CHECK_ERRORS --no-fail || return $?

	case $MODE in
		cached-default )
			[[ $RESET_CACHED_TEMPLATE =~ true ]] \
				&& rm "$__SCWRYPTS_ENVIRONMENT_CACHE__SHELL" &>/dev/null

			[ -f "$__SCWRYPTS_ENVIRONMENT_CACHE__SHELL" ] \
				|| _SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES ${PASSTHROUGH_ARGS[@]} > "$__SCWRYPTS_ENVIRONMENT_CACHE__SHELL"

			cat "$__SCWRYPTS_ENVIRONMENT_CACHE__SHELL"
			;;

		specific-environment )
			[[ $RESET_CACHED_TEMPLATE =~ true ]] \
				&& WARNING 'using --environment-name will never use cached template; no need for --reset-cache'

			_SCWRYPTS_ENVIRONMENT__CONVERT_SHELL_VALUES ${PASSTHROUGH_ARGS[@]}
			;;
	esac
}

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
					|| ERROR "unknown argument '$1'" \
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
		_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE_WITH_VALUE_KEYS --environment-name "$ENVIRONMENT_NAME"
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

			[ -f "$GROUP_CONFIG_FILENAME" ] && {
				[[ $(head -n1 "$GROUP_CONFIG_FILENAME") =~ ^---$ ]] || echo ---
				cat "$GROUP_CONFIG_FILENAME"
			}
		done
	} \
		| _SCWRYPTS_ENVIRONMENT__COMBINE_TEMPLATE_FILES \
		| YQ -P \
		| sed -z 's/\n[a-z]/\n&/g' \
		| sed 's/value: null$/value:/; /\svalue:/G' \
		;
}

_SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE_WITH_VALUE_KEYS() {
	SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE $@ \
		| YQ '(.. | select(has(".ENVIRONMENT"))) += {
				"selection": [],
				"value": null
			}
			' \
		| sed 's/ ""$//'
}
