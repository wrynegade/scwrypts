DEPENDENCIES+=(jo jq printf)

utils.io.print() {
	local \
		message \
		prefix prefix_delimiter=' : ' color \
		minimum_log_level ignore_minimum_log_level=false \
		print_to_stderr=true \
		print_to_stdout=false \
		last_line_end=$'\n' \
		variables=() \
		;

	# since this function can be used outside of scwrypts, we bump log
	# level to maximum to avoid confusion of "why isn't my print
	# statment working"
	[[ "${SCWRYPTS_LOG_LEVEL:=${LOG_LEVEL}}" ]] \
		|| local SCWRYPTS_LOG_LEVEL=4

	[[ "${SCWRYPTS_OUTPUT_FORMAT}" ]] \
		|| local SCWRYPTS_OUTPUT_FORMAT=pretty

	local _s
	while [[ "${#}" -gt 0 ]]
	do
		_s=1
		case "${1}" in
			( --prefix            ) _s=2; prefix="${2}"                       ;;
			( --prefix-delimiter  ) _s=2; prefix_delimiter="${2}"             ;;
			( --color             ) _s=2; color="${2}"                        ;;
			( --minimum-log-level ) _s=2; minimum_log_level="${2}"            ;;
			( --format            ) _s=2; local SCWRYPTS_OUTPUT_FORMAT="${2}" ;;

			( -v ) _s=2  # appends 'name=value' to the end of the message
				variables+=("${2}")
				;;

			( --force-print )
				ignore_minimum_log_level=true
				;;

			( --stdout )
				print_to_stdout=true
				print_to_stderr=false
				;;

			( --no-line-end )  # only applicable to some formats (see below)
				last_line_end=''
				;;

			( * )
				[[ "${message}" ]] && message+=" ${1}" || message="${1}"
				;;
		esac

		shift "${_s}" || { echo "ERROR : missing argument for '${1}'" >&2; return 1; }
	done

	: \
		&& [[ "${minimum_log_level}" ]] \
		&& [[ "${ignore_minimum_log_level}" =~ false ]] \
		&& [[ "${SCWRYPTS_LOG_LEVEL}" -lt "${minimum_log_level}" ]] \
		&& return 0

	local variable
	for variable in "${variables[@]}"
	do
		message+=$'\n'" - ${variable}=${(Pq)variable}"
	done

	case ${SCWRYPTS_OUTPUT_FORMAT:l} in
		( raw ) message+="${last_line_end}" ;;

		( pretty )
			message="${color}$({
				while IFS='' read -r line
				do
					[[ ${prefix} =~ ^[[:space:]]\+$ ]] && printf '%s' $'\n'
					printf "%s" "${prefix}${prefix_delimiter}$(echo "${line}" | sed 's/^	\+//; s/ \+$//')"
					prefix="$(printf '%*s' ${#prefix} '')"
				done <<< "${message}"
			})${last_line_end}$(utils.colors.reset)"
			;;

		( json )
			message="$(jo \
				timestamp=$(date +%s) \
				runtime=${SCWRYPTS_RUNTIME_ID} \
				status="$(echo "${prefix}" | sed 's/ .*//')" \
				message="$(echo -n "${message}" | sed 's/^\t\+//')" \
				2>/dev/null || echo "{\"error\":\"your message was too long so I encoded it\",\"messageB64\":\"$(echo "${message}" | base64 | tr -d '\n')\"}"
			)"$'\n'
			;;

		( logfmt )
			local ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

			local level
			case "${prefix}" in
				( ERROR*   ) level=error ;;
				( WARNING* ) level=warn  ;;
				( DEBUG*   ) level=debug ;;
				( TRACE*   ) level=trace ;;
				( *        ) level=info  ;;
			esac

			local msg="${message}"
			msg="${msg//\\/\\\\}"
			msg="${msg//\"/\\\"}"
			msg="${msg//$'\n'/\\n}"

			message="ts=${ts} level=${level} runtime=${SCWRYPTS_RUNTIME_ID} msg=\"${msg}\""$'\n'
			;;

		( * )
			echo "ERROR : unsupported format '${SCWRYPTS_OUTPUT_FORMAT}'" >&2
			return 1
			;;
	esac

	[[ "${print_to_stderr}" =~ true ]] && printf "%s" "${message}" >&2
	[[ "${print_to_stdout}" =~ true ]] && printf "%s" "${message}"

	return 0
}
