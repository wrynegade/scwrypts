
#
# relies on '.locals()' parser functions to:
#   1. auto-define all local variables
#   2. reset local usage and set initial description
#   3. set other standard local variables
#   4. perform ZSHPARSEARGS (see ./parse.zsh)
#
# usage:
#
# local DESCRIPTION=   # put your '--help' description here
# local PARSERS=()     # add all non-default parsers here
# eval "$(utils.autosetup)"
#
# you can use the '--debug' flag to see what's actually being
# set up here:
#
# eval "$(utils.autosetup --debug)"
#

utils.parse.autosetup() {
	local USE_DEFAULT_PARSERS=true
	local DEBUG=false

	[[ ${(t)PARSERS} =~ array ]] || local PARSERS=()

	local _S ERRORS=0
	while [[ $# -gt 0 ]]
	do
		_S=1

		case $1 in
			( --no-default-parsers )
				USE_DEFAULT_PARSERS=false
				;;
			( --debug )
				# this can be tricky debugging, but these messages are not always helpful
				# to see when SCWRYPTS_LOG_LEVEL is high
				DEBUG=true
				;;
			( * )
				echo.error "utils.autosetup error; unknown argument $1"
				;;
		esac

		[[ ${_S} -le $# ]] \
			&& shift ${_S} \
			|| shift $# \
			;
	done

	utils.check-errors --no-usage --no-fail || {
		echo "echo.error 'utils.autosetup error'; return 127;"
		return 127
	}

	case ${USE_DEFAULT_PARSERS} in
		( false ) ;;
		( true )
			PARSERS=(${funcstack[2]}.parse ${PARSERS[@]} utils.parse.args utils.parse.help)
			;;
	esac

	[[ ${DEBUG} =~ true ]] \
		&& echo.debug --force-print "utils.autosetup : parsers : ${PARSERS[@]}"

	for P in ${PARSERS[@]}
	do
		command -v ${P}.locals &>/dev/null || continue
		which ${P}.locals | sed '1d; $d;'

		[[ ${DEBUG} =~ true ]] \
			&& echo.debug --force-print "utils.autosetup : parser ${P} locals\n$(which ${P}.locals | sed 's/^/ /; 1d; $d;')"
	done | sed 's^\s*local \([A-Z0-9a-z_]*\)\(=\(.*\)\)*$[ "$\1" ] || local \1=\3'

	usage.reset

	echo "local USAGE__description=$(printf "%q " "${DESCRIPTION}")"
	echo "local USAGE__usage=${funcstack[2]}"
	echo "local ERRORS=0"
	echo "local POSITIONAL_ARGS=0"

	echo '
		utils.parse $@ || {
			local ERROR_CODE=$?
			unset PARSERS
			case $ERROR_CODE in
				-1 ) return 0 ;;  # -h | --help
				*  ) return $ERROR_CODE ;;
			esac
		}
		unset PARSERS
	'
}
