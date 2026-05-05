normalize.boolean() {
	local DESCRIPTION='
		normalizes common boolean values to exact values "true" and "false"

		note: mutates the target variable based on operation mode (see below)
	'
	local PARSERS=()
	eval "$(utils.parse.autosetup)"
	##########################################

	local variable_value="${(P)variable}"

	case "${variable_value}" in
		( false | FALSE | False | no  | NO  | No  | n | N | disable* | DISABLE* | Disable* | 0 )
			variable_value=false
			;;
		( true  | TRUE  | True  | yes | YES | Yes | y | Y | enable*  | ENABLE*  | Enable*  | 1 )
			variable_value=true
			;;
		( * )
			case "${default}" in
				( '' )
					echo.error "invalid boolean value ${variable}='${variable_value}'"
					return 1
					;;
				( * )
					[[ "${variable_value}" == '' ]] \
						|| echo.warning "unknown boolean value ${variable}='${variable_value}' (using default '${default}')"

					variable_value="${default}"
					;;
			esac
			;;
	esac

	case "${mode}" in
		( export ) export ${variable}="${variable_value}" ;;
		( set    )        ${variable}="${variable_value}" ;;
		( echo   ) ;;
	esac
	echo "${variable_value}"
}

normalize.boolean.parse.locals() {
	local ARGS=()
	local variable
	local default
	local mode=export
}

normalize.boolean.parse() {
	local parsed=0

	case "${1}" in
		( --variable ) parsed=2; variable="${2}" ;;
		( --default  ) parsed=2; default="${2}"  ;;
		( --mode     ) parsed=2; mode="${2}"     ;;
	esac

	return "${parsed}"
}

normalize.boolean.parse.usage() {
	USAGE__options+='
		--variable <string>   (required) the environment variable to check
		--default <value>     whether a default value is enabled (default: no default value allowed)

		--mode <string>   operation mode; one of the following:
		                    export : "export" the variable on success (default)
		                    set    : execute "VARIABLE_NAME=<value>" and allow parent context to determine variable scope
		                    echo   : only echo normalized value (do not mutate the variable)
	'

	USAGE__args+='
		$1   variable name: when used instead of the above, uses --mode=echo --default=false
	'
}

normalize.boolean.parse.validate() {
	case "${variable}" in
		( '' )
			variable="${ARGS[1]}"
			[[ "${default}" ]] || default=false
			[[ "${mode}"    ]] || mode=echo
			;;
	esac

	[[ "${variable}" ]] || echo.error "missing --variable-name"

	case "${mode}" in
		( export | set | echo ) ;;
		( * ) echo.error "invalid mode '${mode}'" ;;
	esac
}
