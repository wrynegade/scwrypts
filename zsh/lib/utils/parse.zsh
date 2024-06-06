# eval "$ZSHPARSEARGS"
# will handle default cases; useful if no custom negative codes need to be processed
ZSHPARSEARGS='
ZSHPARSEARGS $@ || {
	local ERROR_CODE=$?
	case $ERROR_CODE in
		-1 ) return 0 ;;  # -h | --help
		*  ) return $ERROR_CODE ;;
	esac
}
'

ZSHPARSEARGS() {
	#
	# Parses all arguments using PARSERS array; return value breaks the typical
	# success/failure code paradigm:
	#
	#   returns  0  if all arguments were parsed successfully (success)
	#   returns >0  for every argument which failed to parse successfully (failure)
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
	# invoking 'ZSHPARSEARGS $@'
	#

	local PARSER VALID_PARSERS=()
	local DEFAULT_PARSERS=()
	[ $NO_DEFAULT_PARSERS ] || {
		PARSERS+=(
			ZSHPARSEARGS__ARGS
			ZSHPARSEARGS__HELP
		)
	}

	for PARSER in ${PARSERS[@]}
	do
		command -v ${PARSER}__safety &>/dev/null || {
			VALID_PARSERS+=($PARSER)
			continue
		}

		${PARSER}__safety && VALID_PARSERS+=($PARSER)
	done

	for PARSER in ${VALID_PARSERS[@]}
	do
		command -v ${PARSER}__usage &>/dev/null && ${PARSER}__usage
	done

	local EARLY_ESCAPE_CODE _S ERRORS=0 POSITIONAL_ARGS=0
	while [[ $# -gt 0 ]]
	do
		_S=0
		for PARSER in ${VALID_PARSERS[@]}
		do
			$PARSER $@
			((_S+=$?))

			[ $EARLY_ESCAPE_CODE ] && return $EARLY_ESCAPE_CODE

			[[ $_S -gt 0 ]] && break
		done

		[[ $_S -gt 0 ]] \
			|| ERROR "unknown argument '$1'" \
			|| ((_S+=1))


		[[ $_S -le $# ]] \
			|| ERROR "invalid value(s) for '$1'" \
			|| _S=$#

		shift $_S
	done

	for PARSER in ${VALID_PARSERS[@]}
	do
		command -v ${PARSER}__validate &>/dev/null || continue

		${PARSER}__validate
	done

	CHECK_ERRORS --no-fail
}

#####################################################################

ZSHPARSEARGS__HELP() {
	#
	# parse the -h|--help argument
	#
	# if USAGE string and command are available, sets escape code '-1'
	# when -h or --help is detected (program should 'return 0' immediately)
	#
	local PARSED=0
	case $1 in
		-h | --help )
			((PARSED+=1)) 
			USAGE
			EARLY_ESCAPE_CODE=-1
			;;
	esac

	# return value breaks the conventional "0" = success and "non-0" = failure
	# in "parser" functions, the return value must declare _how many arguments were
	# parsed_ rather than success/failure status
	return $PARSED
}

ZSHPARSEARGS__HELP__usage() {
	#
	# PARSER__usage functions can be declared to automatically inject the
	# proper usage values when the parser is used.
	#
	# Include an extra "newline" character at the beginning to separate
	# the help text by a line
	#
	USAGE__options+="\n
		-h, --help   print this message and exit
	"
}

ZSHPARSEARGS__HELP__safety() {
	# optional "PARSER__safety" function; prevents the parser from being used if the conditions are not met

	# skip this parser with NO_DEFAULT_HELP=true
	[[ $NO_DEFAULT_HELP =~ true ]] && return 1

	# skip this parser if no usage value + function are defined
	[ "$USAGE" ] && command -v USAGE &>/dev/null
}

#####################################################################

ZSHPARSEARGS__ARGS() {
	#
	# parse remaining args into ARGS array
	#
	# local ARGS=()
	# local ARGS_FORCE=allowed   setting this to 'allowed' will ensure everything after '--' is part of the ARGS array
	local PARSED=0

	[ $ARGS_FORCE ] || local ARGS_FORCE=false

	case $ARGS_FORCE in
		true )
			ARGS+=($1)
			PARSED=1
			;;

		allowed )
			case $1 in
				-h | --help )  # filter default cases
					;;
				-- )
					ARGS_FORCE=true
					PARSED=1
					;;
				* )
					ARGS+=($1)
					PARSED=1
					;;
			esac
			;;

		false )
			case $1 in
				-h | --help )  # filter default cases
					;;
				* )
					ARGS+=($1)
					PARSED=1
					;;
			esac
			;;
	esac

	return $PARSED
}

ZSHPARSEARGS__ARGS__usage() {
	case $ARGS_FORCE in
		allowed )
			USAGE__usage+=' -- [...args...]'
			;;
		* )
			USAGE__usage+=' [...args...]'
			;;
	esac
}

ZSHPARSEARGS__ARGS__safety() {
	# skip this parser with NO_DEFAULT_PARSEARGS=true
	[[ $NO_DEFAULT_PARSEARGS =~ true ]] && return 1

	# skip this parser if 'local ARGS=()' is not declared
	[[ ${(t)ARGS} =~ array ]] || return 1

	# skip this parser if 'ARGS' is not empty
	[[ ${#ARGS[@]} -eq 0 ]] || return 1
}
