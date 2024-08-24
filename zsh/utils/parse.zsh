#
# when you don't need to check any special negative cases,
# you can simply set up your PARSERS=() array and other local
# variable declarations, then run the following line:
#
# eval "$ZSHPARSEARGS"
#
# This will populate variables, run all validators, and handle
# the special '--help' case, forcing an early 'return 0' after
# parsing the args.
#
ZSHPARSEARGS='
utils.parse $@ || {
	local ERROR_CODE=$?
	case $ERROR_CODE in
		-1 ) return 0 ;;  # -h | --help
		*  ) return $ERROR_CODE ;;
	esac
}
'

utils.parse() {
	#
	# Parses all arguments using PARSERS array; return value breaks the typical
	# success/failure code paradigm:
	#
	#   returns  0  if all arguments were parsed successfully (success)
	#   returns >0  a count of every argument which failed to parse successfully (failure)
	#
	#   returns -1  if parent program should "return 0" immediately (success, but signal program end; e.g. --help should print usage and return 0)
	#
	#   other _negative return codes_ can be processed in any custom way
	#
	#
	# Makes argument parsing reusable in zsh. Best-practice argument
	# parsing involves looping across the $@ args, processing and 'shift'-ing
	# arguments until there are none left, but this can lead to a lot
	# of boilerplate. While there _are_ utilities to try and simplify this,
	# I've found their API to be quite complex and inconsistent across
	# different environments.
	#
	# By including "parser" functions in the 'PARSERS=()' array, you can
	# perform parsing logic (first element is highest priority, last element is
	# lowest priority). A sample parser function is defined below.
	#
	# If variable values are set in the caller function, proper usage requires
	# declaration of "local VARIABLE_NAME" in that parent caller _before_
	# invoking 'utils.zshparseargs $@'
	#
	local PARSER VALID_PARSERS=()
	local DEFAULT_PARSERS=()

	[[ ${DEFAULT_PARSERS[@]-1} =~ ^utils.parse.help$ ]] \
		&& local NO_DEFAULT_PARSERS=true  # autosetup preloads default parsers

	[ ${NO_DEFAULT_PARSERS} ] || {
		# automatically includes 'MY_FUNCTION.parse()' as 1st parser when parsing for 'MY_FUNCTION()'
		[[ ${funcstack[2]} =~ ^[(]eval[)]$ ]] \
			&& PARSERS=(${funcstack[3]}.parse ${PARSERS}) \
			|| PARSERS=(${funcstack[2]}.parse ${PARSERS}) \
			;

		PARSERS+=(utils.parse.args utils.parse.help)
	}

	for PARSER in ${PARSERS[@]}
	do
		command -v ${PARSER} &>/dev/null || continue
		command -v ${PARSER}.safety &>/dev/null || {
			VALID_PARSERS+=(${PARSER})
			continue
		}

		${PARSER}.safety && VALID_PARSERS+=(${PARSER})
	done

	for PARSER in ${VALID_PARSERS[@]}
	do
		command -v ${PARSER}.usage &>/dev/null && ${PARSER}.usage
	done

	local EARLY_ESCAPE_CODE _S ERRORS=0 POSITIONAL_ARGS=0
	while [[ $# -gt 0 ]]
	do
		_S=0
		for PARSER in ${VALID_PARSERS[@]}
		do
			${PARSER} $@
			((_S+=$?))

			[ ${EARLY_ESCAPE_CODE} ] && return ${EARLY_ESCAPE_CODE}

			[[ ${_S} -gt 0 ]] && break
		done

		[[ ${_S} -gt 0 ]] \
			|| echo.error "unknown argument '$1'" \
			|| ((_S+=1))


		[[ ${_S} -le $# ]] \
			|| echo.error "invalid value(s) for '$1'" \
			|| _S=$#

		shift ${_S}
	done

	for PARSER in ${VALID_PARSERS[@]}
	do
		command -v ${PARSER}.validate &>/dev/null || continue

		${PARSER}.validate
	done

	utils.check-errors --no-fail
}

#####################################################################
### default parsers #################################################
#####################################################################

# while it is not recommended to leave so many comments on YOUR parser
# functions, these defaults provide verbose comments to provide you
# how-to-write-parser-functions reference
#
# refer to them in-order if you are trying to write a parser for the
# first time

source "${0:a:h}/parse.help.zsh"
source "${0:a:h}/parse.args.zsh"


#####################################################################
### the easy-but-removed way to go ##################################
#####################################################################

source "${0:a:h}/parse.autosetup.zsh"
