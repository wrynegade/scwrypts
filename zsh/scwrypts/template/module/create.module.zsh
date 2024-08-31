#####################################################################

${scwryptsmodule}() {
	eval "$(utils.parse.autosetup)"
	##########################################


	[ "${TEMPLATE}" ] \
		|| ERROR

	case ${MODE} in
		( stdout )
			echo "${TEMPLATE}"
			;;
	esac
}

#####################################################################

${scwryptsmodule}.parse() {
	local PARSED=0

	case $1 in
		#( -g | --group ) PARSED=2; MODULE_GROUP="$2" ;;
		#( -n | --name  ) PARSED=2; MODULE_NAME="$2"  ;;

		#( --stdout ) PARSED=1; MODE=stdout ;;
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

${scwryptsmodule}.parse.locals() {
	local TEMPLATE

	#local MODE=interactive  # TODO
	#local MODULE_GROUP
	#local MODULE_NAME

	local MODE=stdout
	local INCLUDE_HELP=${SCWRYPTS_GENERATOR__SHOW_HELP}  # default is configurable
}

${scwryptsmodule}.parse.usage() {
	USAGE__options+="
		--include-help <true|false>   whether to include help comments in the description (default : ${SCWRYPTS_GENERATOR__SHOW_HELP})
	"

	USAGE__description="
		sets up recommended boilerplate for a new scwrypts module
	"
}

${scwryptsmodule}.parse.validate() {
	TEMPLATE="$(cat -- "$(scwrypts.config.group scwrypts root)/zsh/scwrypts/template/module/template.zsh")"

	[[ ${INCLUDE_HELP} =~ false ]] \
		&& TEMPLATE="$(echo "${TEMPLATE}" | sed '/# /d; /^\s*#$/d')"

	[ "${TEMPLATE}" ] \
		|| echo.error 'error generating template :c'
}
