#####################################################################

${scwryptsmodule}.include-help() {
	local PARSED=0

	case $1 in
		( --include-help )
			PARSED=2
			case $2 in
				( true | false ) INCLUDE_HELP=$2 ;;
				( * ) echo.error "invalid value for --include-help '$2'" ;;
			esac
			;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.include-help.locals() {
	local INCLUDE_HELP=${SCWRYPTS_GENERATOR__SHOW_HELP}  # default is configurable

	local TEMPLATE_FILE   # by providing the TEMPLATE_FILE, the TEMPLATE literal text is automatically generated
	local TEMPLATE
}

${scwryptsmodule}.include-help.usage() {
	USAGE__options+="
		--include-help <true|false>   whether to include help comments in the description
		                              (default : ${SCWRYPTS_GENERATOR__SHOW_HELP})
	"
}

${scwryptsmodule}.include-help.validate() {
	[ "${TEMPLATE_FILE}" ] && {
		[ -f "${TEMPLATE_FILE}" ] \
			|| echo.error "no template at '${TEMPLATE_FILE}'" \
			|| return

		case ${INCLUDE_HELP} in
			( true )
				TEMPLATE="$(cat -- "${TEMPLATE_FILE}")"
				;;
			( false )
				TEMPLATE="$(sed -- '/# /d; /^\s*#$/d' "${TEMPLATE_FILE}")"
				;;
		esac

		[ "${TEMPLATE}" ] \
			|| echo.error "failed to generate template '${TEMPLATE_FILE}'"
	}
}

#####################################################################

${scwryptsmodule}.mode-select() {
	local PARSED=0

	case $1 in
		#( -g | --group ) PARSED=2; MODULE_GROUP="$2" ;;
		#( -n | --name  ) PARSED=2; MODULE_NAME="$2"  ;;

		( --mode )
			PARSED=2
			TEMPLATE_GENERATION_MODE=$2
			;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.mode-select.locals() {
	local TEMPLATE_GENERATION_MODE=stdout

	#local MODULE_GROUP
	#local MODULE_NAME
}

${scwryptsmodule}.mode-select.usage() {
	USAGE__options+='
		--mode <string>   one of the supported template generation modes
		                  supported : (stdout)
	'
}

${scwryptsmodule}.mode-select.validate() {
	case ${TEMPLATE_GENERATION_MODE} in
		( stdout ) ;;
		( * )
			echo.error "invalid template output mode '${TEMPLATE_GENERATION_MODE}'"
			;;
	esac
}
