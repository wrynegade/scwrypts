DEPENDENCIES+=(jo jq printf)

utils.io.print() {
	local \
		MESSAGE \
		PREFIX COLOR \
		MINIMUM_LOG_LEVEL IGNORE_MINIMUM_LOG_LEVEL=false \
		PRINT_TO_STDERR=true \
		PRINT_TO_STDOUT=false \
		LAST_LINE_END='\n' \
		;

	[ ${SCWRYPTS_LOG_LEVEL}     ] || local SCWRYPTS_LOG_LEVEL=4
	[ ${SCWRYPTS_OUTPUT_FORMAT} ] || local SCWRYPTS_OUTPUT_FORMAT=pretty

	local _S
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			( --prefix )
				_S=2
				PREFIX="$2"
				;;

			( --color )
				_S=2
				COLOR="$2"
				;;

			( --minimum-log-level )
				_S=2
				MINIMUM_LOG_LEVEL=$2
				;;

			( --force-print )
				IGNORE_MINIMUM_LOG_LEVEL=true
				;;

			( --stdout )
				PRINT_TO_STDOUT=true
				PRINT_TO_STDERR=false
				;;

			( --no-line-end  )
				LAST_LINE_END=''
				;;

			( --format ) 
				_S=2
				local SCWRYPTS_OUTPUT_FORMAT=$2
				;;

			( * )
				[ "$MESSAGE" ] && MESSAGE+=" $1" || MESSAGE="$1"
				;;
		esac

		[[ ${_S} -le $# ]] && shift ${_S} || { echo "echo.error : missing argument for '$1'" >&2; return 1; }
	done

	[ "${MESSAGE}" ] || return 1

	: \
		&& [ "${MINIMUM_LOG_LEVEL}" ] \
		&& [[ "${IGNORE_MINIMUM_LOG_LEVEL}" =~ false ]] \
		&& [[ "${SCWRYPTS_LOG_LEVEL}" -lt "${MINIMUM_LOG_LEVEL}" ]] \
		&& return 0


	MESSAGE="$(echo "${MESSAGE}" | sed 's/^	\+//; s/%/%%/g')"
	case ${SCWRYPTS_OUTPUT_FORMAT} in
		raw ) MESSAGE+="${LAST_LINE_END}" ;;
		pretty )
			MESSAGE="${COLOR}$({
				while IFS='' read line
				do
					[[ ${PREFIX} =~ ^[[:space:]]\+$ ]] && printf '\n'

					printf "${PREFIX} : $(echo "${line}" | sed 's/^	\+//; s/ \+$//')"

					PREFIX='          '
				done <<< $(echo "${MESSAGE}" | sed 's/%/%%/g')
			})${LAST_LINE_END}$(utils.colors.reset)"
			;;
		json )
			MESSAGE="$(jo \
				timestamp=$(date +%s) \
				runtime=${SCWRYPTS_RUNTIME_ID} \
				status="$(echo "${PREFIX}" | sed 's/ .*//')" \
				message="$(echo -n "${MESSAGE}" | sed 's/^\t\+//' | jq -Rs)" \
			)\n"
			;;
		* )
			echo "echo.error : unsupported format '${SCWRYPTS_OUTPUT_FORMAT}'" >&2
			return 1
			;;
	esac


	[[ ${PRINT_TO_STDERR} =~ true ]] && printf -- "${MESSAGE}" >&2
	[[ ${PRINT_TO_STDOUT} =~ true ]] && printf -- "${MESSAGE}"

	return 0
}
