#
# parses unmatched args into the 'local ARGS=()' array; as seen below,
# this will only parse unmatched args if the 
# parses '-h' or '--help', prints usage, and returns early
#

# when parsers set values to variables, mention them in a comment on the
# first line of the function, so it is clear what variables must be set
# in the parent function

utils.parse.args() {
	# local ARGS=()
	# local ARGS_FORCE=allowed   typically you want this to be 'allowed', but see below for details
	local PARSED=0
	[ $ARGS_FORCE ] || local ARGS_FORCE=false

	case $ARGS_FORCE in
		#
		# ARGS_FORCE=true means no arguments will be filtered before going
		# into the ARGS array; typically this is set _after_ hitting the '--'
		# argument (done automatically below)
		#
		true )
			((POSITIONAL_ARGS+=1))
			PARSED=1
			ARGS+=($1)
			;;

		#
		# ARGS_FORCE=allowed will filter out flag/option arguments (e.g '-h' or '--help'),
		# but after a '--' is parsed, ARGS_FORCE is set to 'true'. For example:
		#
		# MY_FUNCTION arg1 arg2 --help
		#   would set ARGS=(arg1 arg2) and ignore the '--help'
		#
		# MY_FUNCTION -- arg1 arg2 --help
		#   would set ARGS=(arg1 arg2 --help); consuming the '--help'
		#
		allowed )
			case $1 in
				-[a-zA-Z0-9]* | --[a-zA-Z[0-9]* )
					;;

				-- ) PARSED=1; ARGS_FORCE=true ;;

				* )
					((POSITIONAL_ARGS+=1))
					PARSED=1
					ARGS+=($1)
					;;
			esac
			;;

		#
		# ARGS_FORCE=false will _always_ filter out flag/option arguments; although you
		# typically want ARGS_FORCE=allowed, this is the 'default' option when ARGS_FORCE
		# is not specified (required to allow safe fallthrough when no args should be parsed)
		#
		false )
			case $1 in
				-[a-zA-Z0-9]* | --[a-zA-Z[0-9]* )
					;;

				* )
					((POSITIONAL_ARGS+=1))
					PARSED=1
					ARGS+=($1)
					;;
			esac
			;;
	esac

	return $PARSED
}

utils.parse.args.usage() {
	# don't auto-add "args" to the usage string if it's already there
	[[ $USAGE__usage =~ args ]] && return 0

	case $ARGS_FORCE in
		allowed )
			USAGE__usage+=' -- [...args...]'
			;;
		* )
			USAGE__usage+=' [...args...]'
			;;
	esac

	# USAGE__args should be updated by the parent function
}

utils.parse.args.safety() {
	# skip this parser with NO_DEFAULT_PARSEARGS=true
	[[ $NO_DEFAULT_PARSEARGS =~ true ]] && return 1

	# skip this parser if 'local ARGS=()' is not declared
	[[ ${(t)ARGS} =~ array ]] || return 1

	# skip this parser if 'ARGS' is not empty
	[[ ${#ARGS[@]} -eq 0 ]] || return 1
}
