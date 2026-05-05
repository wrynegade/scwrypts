export _SCWRYPTS_DEFAULT_LOG_LEVEL=3
typeset -gA SCWRYPTS_LOG_LEVELS

### level 0 : only print forced messages ############################
SCWRYPTS_LOG_LEVELS[0]=fatal

### level 1 : only print errors #####################################
SCWRYPTS_LOG_LEVELS[1]=error

echo.error.color() { utils.colors.red; }
echo.error() {  # command encountered an error
	utils.io.print "${@}" --minimum-log-level 1 --prefix "ERROR    ✖" --color  "$(echo.error.color)"
	((ERRORS+=1))
	return ${ERRORS}
}

echo.error.user-abort() {  # consistent verbiage for user-aborted workflows
	echo.error 'user abort' "${@}"
}

### level 2 : print errors & warnings ###############################
SCWRYPTS_LOG_LEVELS[2]=warning

echo.warning.color() { utils.colors.yellow; }
echo.warning() {  # warning-level messages; not errors
	utils.io.print "${@}" --minimum-log-level 2 --prefix "WARNING  " --color  "$(echo.warning.color)"
	((WARNINGS+=1))
	return 0
}

echo.warning.deprecation() { # emit a deprecation warning
	local removed_in_version="${1}"
	local message="${2:-this function will be removed}"

	# "scwrypts/vX.X" is the default (specifies only vX.X), but custom version allowed
	[[ "${removed_in_version}" =~ ^v[0-9.]+$ ]] \
		&& removed_in_version="scwrypts/${removed_in_version}"

	echo.warning "DEPRECATED : ${funcstack[2]} : ${message} in ${removed_in_version}"
}

### level 3 : print status messages & user information ##############
SCWRYPTS_LOG_LEVELS[3]=status

echo.success.color() { utils.colors.green; }
echo.success() {  # command completed successfully
	utils.io.print "${@}" --minimum-log-level 3 --prefix "SUCCESS  ✔" --color  "$(echo.success.color)"
	return 0
}

echo.status.color() { utils.colors.blue; }
echo.status() {  # general status updates (prefer this to generic 'echo')
	utils.io.print "${@}" --minimum-log-level 3 --prefix "STATUS    " --color  "$(echo.status.color)"
	return 0
}

echo.reminder.color() { utils.colors.bright-magenta; }
echo.reminder() {  # sysadmin reminder or important notice to users
	utils.io.print "${@}" --minimum-log-level 3 --prefix "REMINDER " --color "$(echo.reminder.color)"
	return 0
}

### level 4 : include debug messages ################################
SCWRYPTS_LOG_LEVELS[4]=debug

echo.debug.color() { utils.colors.white; }
echo.debug() {  # helpful during development or (sparingly) to help others' development
	set -- "${DEBUG_ARGS[@]}" "${@}"
	case "${@[(re)--force-print]}" in
		( --force-print ) ;;  # if --force-print is present; always print
		( * ) # early exit since trace injects state information which is slow
			[[ "${SCWRYPTS_LOG_LEVEL:=${LOG_LEVEL}}" ]] || return 0
			[[ "${SCWRYPTS_LOG_LEVEL}" -lt 4 ]] && return 0
			;;
	esac

	local args=() extra_print_lines=() variable_name message_count=0
	local _s
	while [[ "${#}" -gt 0 ]]
	do
		_s=1
		case "${1}" in
			( -v ) _s=2
				variable_name="${2}"
				extra_print_lines+="\n> DEBUG::var${variable_name}${(t)${(P)variable_name}}${(P)variable_name}$(echo "${(P)variable_name}" | grep -q . || echo "$(echo.warning.color)<variable empty>$(echo.debug.color)")"
				;;

			( --eval ) _s=2
				args+=("$(eval "${2}" 2>&1 | grep . || echo "failed to run ${2}")")
				((message_count+=1))
				;;

			( -* ) args+=("${1}") ;;
			( '' ) ;;  # a '' is inserted from empty TRACE_ARGS
			( *  ) args+=("${1}") ; ((message_count+=1)) ;;
		esac
		shift "${_s}" || shift "${#}"
	done
	unset _s

	[[ "${message_count}" -eq 0 ]] && args+=("<debug called by $(utils.colors.cyan)${funcstack[2]:-<unknown>~}$(echo.debug.color)>")

	utils.io.print "${args[@]}" --minimum-log-level 4 --prefix "DEBUG    ℹ" --color "$(echo.debug.color)" \
		$'\n'"$(
			[[ "${extra_print_lines[@]}" ]] && {
				echo "> DEBUG::var$(utils.colors.bright-yellow)variabletypevalue$(echo.debug.color)"
				echo "> DEBUG::var---------$(echo.debug.color)"
				echo "${extra_print_lines[@]}" | sort -u
				echo "> DEBUG::var---------$(echo.debug.color)"
			} | column -ts ''
			echo "> DEBUG::called-by : ${funcstack[2]}"
			echo "> DEBUG::funcstack : $(echo "${funcstack[@]:1}" | sed 's/ (anon) (eval) (anon)$/ scwrypts/')"
			echo "> DEBUG::timestamp : $(date +%s)"
		)"

	return 0
}

### level 5 : include full trace (may be sensitive) #################
SCWRYPTS_LOG_LEVELS[5]=trace

echo.trace.color() { utils.colors.reset; }
echo.trace() {
	(( ${funcstack[(Ie)echo.trace]} > 1 )) && return 0 # escape early if echo.trace is recursively nesting
	set -- "${TRACE_ARGS[@]}" "${DEBUG_ARGS[@]}" "${@}"
	case "${@[(re)--force-print]}" in
		( --force-print ) ;;  # if --force-print is present; always print
		( * ) # early exit since trace injects state information which is slow
			[[ "${SCWRYPTS_LOG_LEVEL:=${LOG_LEVEL}}" ]] || return 0
			[[ "${SCWRYPTS_LOG_LEVEL}" -lt 5 ]] && return 0
			;;
	esac

	local args=() extra_print_lines=() variable_name message_count=0
	local _s
	while [[ "${#}" -gt 0 ]]
	do
		_s=1
		case "${1}" in
			( -v ) _s=2
				variable_name="${2}"
				extra_print_lines+="\n> TRACE::var${variable_name}${(t)${(P)variable_name}}${(P)variable_name}$(echo "${(P)variable_name}" | grep -q . || echo "$(echo.warning.color)<variable empty>$(echo.trace.color)")"
				;;

			( --eval ) _s=2
				args+=("$(eval "${2}" 2>&1 | grep . || echo "failed to run ${2}")")
				((message_count+=1))
				;;

			( -* ) args+=("${1}") ;;
			( '' ) ;;  # a '' is inserted from empty TRACE_ARGS / DEBUG_ARGS
			( *  ) args+=("${1}") ; ((message_count+=1)) ;;
		esac
		shift "${_s}" 2>/dev/null || shift "${#}"
	done
	unset _s

	[[ "${message_count}" -eq 0 ]] && args+=("<trace called by ${funcstack[2]:-<unknown>~}>")

	utils.io.print "${args[@]}" --minimum-log-level 5 --prefix "TRACE     " --color "$(echo.trace.color)" \
		$'\n'"$(
			[[ "${extra_print_lines[@]}" ]] && {
				echo "> TRACE::var$(utils.colors.bright-yellow)variabletypevalue$(echo.trace.color)"
				echo "> TRACE::var---------$(echo.trace.color)"
				echo "${extra_print_lines[@]}" | sort -u
				echo "> TRACE::var---------$(echo.trace.color)"
			} | column -ts ''
			echo "> TRACE::called-by : ${funcstack[2]}"
			echo "> TRACE::funcstack : ${funcstack[@]}"
			echo "> TRACE::timestamp : $(date +%s)"
		)"


	return 0
}

#####################################################################

echo.prompt() {
	local prompt_print_args=()
	local response response_set=false only_response=false
	local response_print_args=()

	local _s
	while [[ "${#}" -gt 0 ]]
	do
		_s=1
		case "${1}" in
			( --response ) _s=2; response_set=true; response="${2}" ;;
			( --only-response ) only_response=true ;;

			( * ) prompt_print_args+=("${1}") ;;
		esac
		shift "${_s}" || shift "${#}"
	done
	unset _s

	[[ "${response_set}" == true ]] \
		&& response_print_args+=(':' "${response}") \
		|| response_print_args+=(': ' --no-line-end) \
		;

	[[ "${only_response}" == true ]] && {
		utils.io.print "${response}" --prefix-delimiter ''
		return "${?}"
	}

	case "${SCWRYPTS_LOG_LEVEL:-${LOG_LEVEL:-${_SCWRYPTS_DEFAULT_LOG_LEVEL}}}" in
		( 0 )
			case "${SCWRYPTS_OUTPUT_FORMAT:-pretty}" in
				( pretty ) utils.io.print "${prompt_print_args[@]}" "${response_print_args[@]}" --format raw ;;
				( *      ) utils.io.print "${prompt_print_args[@]}" "${response_print_args[@]}" ;;
			esac
			;;

		( * )
			utils.io.print "${prompt_print_args[@]}"   --prefix "PROMPT   " --color $(utils.colors.cyan)
			utils.io.print "${response_print_args[2]}" --prefix "USER     ⌨" --color $(utils.colors.bright-cyan)
			;;
	esac
}
