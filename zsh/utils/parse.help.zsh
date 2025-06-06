#
# parse the -h|--help argument, then requests that the parent function exit early
# by emitting EARLY_ESCAPE_CODE=-1
#

utils.parse.help() {
	local PARSED=0

	case $1 in
		( -h | --help )
			PARSED=1
			utils.io.usage
			EARLY_ESCAPE_CODE=-1

			# setting 'EARLY_ESCAPE_CODE=' will stop ALL argument parsing, forcing
			# ZSHPARSEARGS to immediately return the value ${EARLY_ESCAPE_CODE}
			#
			# negative EARLY_ESCAPE_CODE values are _not_ processed automatically;
			# however, this special case, 'EARLY_ESCAPE_CODE=-1' is handled in the
			# 'eval "$ZSHPARSEARGS"' method of using ZSHPARSEARGS()
			;;

	esac

	# return value breaks the conventional "0" = success and "non-0" = failure
	# in "parser" functions, the return value must declare _how many arguments were
	# parsed_ rather than success/failure status
	return ${PARSED}
}


#
# for a parser named 'MY_PARSER()', the optional 'MY_PARSER.safety()' function
# will check and see _IF_ the parser should be used. All safety functions are run
# at the very beginning of ZSHPARSEARGS.
#
# when the '.safety()' function succeeds, the parser is used
# when the '.safety()' function fails, the parser is SKIPPED
#
# when the '.safety()' function does not exist, the parser is used
#
utils.parse.help.safety() {
	# skip this parser with NO_DEFAULT_HELP=true
	[[ ${NO_DEFAULT_HELP} =~ true ]] && return 1

	# skip this parser if no usage value + function are defined
	[ "${USAGE}" ] && command -v utils.io.usage &>/dev/null || return 1
}


#
# for a parser named 'MY_PARSER()', the optional 'MY_PARSER.usage()' function
# updates 'USAGE__*' values. Usage functions are run _after_ safety functions,
# and are ignored if the safety function causes the parser to be skipped.
#
utils.parse.help.usage() {
	#
	# PARSER.usage functions can be declared to automatically inject the
	# proper usage values when the parser is used.
	#
	# Include an extra "newline" character at the beginning to separate
	# the help text by a line
	#
	USAGE__options+="\n
		-h, --help   print this message and exit
	"
}


#
# for a parser named 'MY_PARSER()', the optional 'MY_PARSER.locals()' function
# defines variables which will be local-scoped to the function which is USING
# the parser
#
# this is primarily meant for use in reusable parsers to avoid boilerplate of
# local variable definition in all use cases
#
# out of convenience, any local-scoped variables will also be available
# throughout all MY_PARSER.*() functions
#
# The utils.parse.help parser does not require any local variables, so consider
# the following example:
#
# ------------------------------------------
#
# my-function() {
#	local PARSERS=(MY_PARSER)
#
#	eval "${ZSHPARSEARGS}"
#
#	echo "my value is ${LOCAL_VARIABLE}"
# }
# # outside of my-function(), the LOCAL_VARIABLE is no longer local-scoped
# # (zsh local-scope "rules" still apply)
#
# MY_PARSER.locals() {
#	local LOCAL_VARIABLE
# }
#
# MY_PARSER() {
#	local PARSED=0
#
#	case $1 in
#		( --value )
#			PARSED=2
#			LOCAL_VARIABLE=$2
#			;;
#	esac
#
#	return ${PARSED}
# }
#
#
# ------------------------------------------


#
# for a parser named 'MY_PARSER()', the optional 'MY_PARSER.validate()' function
# validates parsing errors. Since validate functions are run at the very end of
# ZSHPARSEARGS (after all argument parsing is complete), this is your last chance
# to parsing errors
#
# Note that the return value of this function _is ignored_. You must use the 'ERROR()'
# function to emit errors up to ZSHPARSEARGS
#
# The utils.parse.help parser does not require any validate function, so consider
# the following example:
#
# ------------------------------------------
#
# MY_PARSER() {
#	# local REQUIRED_OPTION
#	local PARSED=0
#
#	case $1 in
#		( --my-required-option )
#			PARSED=2
#			REQUIRED_OPTION=$2
#			;;
#	esac
#
#	return ${PARSED}
# }
#
# MY_PARSER.validate() {
#	[ "${REQUIRED_OPTION}" ] \
#		|| echo.error "missing required option '--my-required-option'"
# }
#
# ------------------------------------------
