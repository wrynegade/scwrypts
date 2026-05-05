utils.environment.check-all() {
	# checks all environment variables in REQUIRED_ENV=()
	[[ "${SCWRYPTS_LOG_LEVEL}" ]] || local SCWRYPTS_LOG_LEVEL=4
	local ERRORS=0 WARNINGS=0

	REQUIRED_ENV=($(printf '%s\n' "${REQUIRED_ENV[@]}" | sort --unique))

	local configuration_variable_name
	for configuration_variable_name in ${REQUIRED_ENV[@]}
	do
		utils.environment.check ${configuration_variable_name} || ((ERRORS+=1))
	done

	return ${ERRORS}
}

utils.environment.check() {
	local ERRORS=0 WARNINGS=0
	local DEBUG_ARGS=() TRACE_ARGS=()

	local configuration_variable_name optional default_value user_json_query
	DEBUG_ARGS+=(-v configuration_variable_name -v optional -v default_value)
	TRACE_ARGS+=(-v user_json_query)

	local lookup_type
	DEBUG_ARGS+=(-v lookup_type)

	local print_value_to_stdout=false
	TRACE_ARGS+=(-v print_value_to_stdout)

	local USAGE="
		usage: utils.environment.check <environment variable> [...options...]

		options:
		  --optional      marks the variable as optional
		  --default       marks the variable as optional and provides a default value
		  --print-value   print the value to stdout

		Verifies the existence of an environment variable in the current
		runtime. When running in scwrypts, allows lookup of environment variable
		values by either environment variable name or config lookup path:

		    utils.environment.check AWS_ACCOUNT
		    utils.environment.check .aws.account

		When in CI, environment _values_ must always come from the corresponding
		configuration env var (even when lookup is a config lookup path)
	"

	local _s _p=0
	while [[ ${#} -gt 0 ]]
	do
		_s=1
		case ${1} in
			( -h | --help )
				utils.io.usage
				return 0
				;;

			( --optional )
				optional=true
				;;

			( --print-value )
				print_value_to_stdout=true
				;;

			( --default )
				[[ ${2} ]] && ((_S+=1)) \
					|| echo.error "missing env var default value" \
					|| break

				[[ ! "${default_value}" ]] \
					|| echo.error "only one default value is supported" \
					|| break

				[[ ${optional} == true ]] \
					&& echo.warning "--optional and --default flags are redundant; remove '--optional' flag"

				default_value="${2}"
				optional=true
				;;

			( * )
				case "$((_p+=1))" in
					( 1 ) configuration_variable_name="${1}"
						;;

					( 2 ) default_value="${1}"
						echo.warning "use of positional argument for default value is DEPRECATED\nplease use --default <value> flag"
						;;

					( * ) echo.error "unknown argument '${1}'"
						;;
				esac
				;;
		esac
		shift "${_s}"
	done
	unset _s _p

	[[ "${configuration_variable_name}" ]] \
		|| echo.error "must provide configuration variable name"

	[[ "${optional}" ]] || optional=false

	case "${configuration_variable_name}" in
		( .* )
			lookup_type=query-path
			[[ "${__SCWRYPT}" ]] \
				|| echo.error "lookup paths cannot be used outside of scwrypts (${configuration_variable_name})"
			;;

		( * )
			lookup_type=environment-variable
			;;
	esac

	utils.check-errors --no-usage || return "${?}"

	##########################################

	# only check env vars once; this is a headache, but serves a substantial performance purpose
	local already_checked_status_suffix=scwrypts_checked_status
	local already_checked_status_variable
	TRACE_ARGS+=(-v already_checked_status_variable)

	local already_checked_status
	DEBUG_ARGS+=(-v already_checked_status)
	case "${lookup_type}" in
		( query-path ) ;;  # can't check early return status just yet
		( * )
			already_checked_status_variable="${configuration_variable_name}__${already_checked_status_suffix}"
			already_checked_status="${(P)already_checked_status_variable}"
			[[ "${already_checked_status}" ]] && {
				# if the previous check failed, we can escape early
				[[ "${already_checked_status}" -ne 0 ]] && echo.trace && return "${already_checked_status}"

				# if we don't need to print, we can escape early
				[[ "${print_value_to_stdout}" == false ]] && echo.trace && return "${already_checked_status}"
			}
			;;
	esac

	# outside of scwrypts, environment must load like CI runtime
	[[ "${__SCWRYPT}" ]] || local CI=true
	DEBUG_ARGS+=(-v CI)

	local configuration_value configuration_values=() check_status=1
	TRACE_ARGS+=(-v configuration_value -v configuration_values)
	case "$(normalize.boolean --variable CI --default false --mode echo)" in
		( true )  # in CI, all environment configuration MUST come from environment
			case "${lookup_type}" in
				( query-path )
					use scwrypts/environment/get-user-json 2>/dev/null

					user_json_query=".configuration${configuration_variable_name}"
					configuration_variable_name="$(scwrypts.environment.get-user-json 2>/dev/null | utils.yq -r "${user_json_query}.\".ENVIRONMENT\"" | grep -v ^null$)"

					[[ "${configuration_variable_name}" ]] \
						|| configuration_variable_name="SCWRYPTS_CONFIG_$(echo "${user_json_query}" | sed 's/[-. ]/_/g' | tr '[:upper:]' '[:lower:]')"

					[[ "${configuration_variable_name}" ]] \
						|| echo.error "no .ENVIRONMENT key is configured for ${user_json_query}, and I failed to autogenerate one" \
						|| return 1
					;;
			esac
			utils.environment.check.environment "${configuration_variable_name}"
			;;

		( false )
			use scwrypts/environment/get-user-json \
				|| echo.error "unable to load required environment library" \
				|| return 1

			case "${lookup_type}" in
				( environment-variable )
					user_json_query=".configuration$(scwrypts.environment.get-user-json | utils.yq -r ".lookup.${configuration_variable_name}" | grep -v ^null$ | sed 's/\.value$//')"
					[[ "${user_json_query}" != '.configuration' ]] \
						|| echo.error "unable to determine lookup value from variable '${configuration_variable_name}'" \
						|| return 1
					;;

				( query-path )
					user_json_query=".configuration${configuration_variable_name}"
					configuration_variable_name="$(scwrypts.environment.get-user-json | utils.yq -r "${user_json_query}.\".ENVIRONMENT\"" | grep -v ^null$)"

					[[ "${configuration_variable_name}" ]] \
						|| configuration_variable_name="SCWRYPTS_CONFIG_$(echo "${user_json_query}" | sed 's/[-. ]/_/g' | tr '[:upper:]' '[:lower:]')"

					[[ "${configuration_variable_name}" ]] \
						|| echo.error "no .ENVIRONMENT key is configured for ${user_json_query}, and I failed to autogenerate one" \
						|| return 1

					# now that we know the name of the variable, we can check early return status
					already_checked_status_variable="${configuration_variable_name}__${already_checked_status_suffix}"
					already_checked_status="${(P)already_checked_status_variable}"
					[[ "${already_checked_status}" ]] && {
						# if the previous check failed, we can escape early
						[[ "${already_checked_status}" -ne 0 ]] && return "${already_checked_status}"

						# if we don't need to print, we can escape early
						[[ "${print_value_to_stdout}" == false ]] && return "${already_checked_status}"
					}
					;;
			esac

			# ensure environment safety; prevent bleed in from user's runtime
			[[ "${already_checked_status}" ]] || unset -- "${configuration_variable_name}"

			local configuration_json="$(scwrypts.environment.get-user-json | utils.yq "${user_json_query}")"
			local configuration_value_type
			DEBUG_ARGS+=(-v configuration_value_type)

			local get_method
			for get_method in \
				environment \
				runtime-override \
				value \
				selection \
				;
			do
				utils.environment.check.${get_method} "${configuration_variable_name}" "${configuration_json}"
				[[ "${configuration_value}"            ]] && break
				[[ "${#configuration_values[@]}" -gt 0 ]] && break
			done
			;;
	esac

	[[ "${configuration_value}"            ]] && check_status=0 && configuration_value_type=scalar
	[[ "${#configuration_values[@]}" -gt 0 ]] && check_status=0 && configuration_value_type=array

	[[ "${check_status}" -eq 0 ]] || {
		case "${optional}" in
			( false ) check_status=1 ;;
			( true  ) check_status=0
				[[ "${default_value}" ]] \
					&& configuration_value="${default_value}" \
					|| echo.warning "environment variable '${configuration_variable_name}' is not set"
				;;
		esac
	}

	export ${already_checked_status_variable}="${check_status}"

	case "${configuration_value_type}" in
		( array )
			[[ "${print_value_to_stdout}" == true ]] && printf '%s\n' "${configuration_values[@]}"
			eval "export ${configuration_variable_name}=(${(q)configuration_values[@]})"
			;;

		( * )
			[[ "${print_value_to_stdout}" == true ]] && echo "${configuration_value}"
			export ${configuration_variable_name}="${configuration_value}"
			;;
	esac

	echo.trace
	return "${check_status}"
}

utils.environment.check.environment() {  # pulls directly from environment : used in CI and after first check
	local configuration_variable_name="${1}"
	#local configuration_json="${2}"

	# used when we need to print the variable after it was already checked once
	case "${(tP)configuration_variable_name}" in
		( '' ) ;; # no value set

		( *array* ) configuration_values=("${(P@)configuration_variable_name}") ;;
		( *       ) configuration_value="${(P)configuration_variable_name}"     ;;
	esac
}

utils.environment.check.runtime-override() {  # support for ENV_VAR__override= : scalar only
	local configuration_variable_name="${1}"
	#local configuration_json="${2}"

	local environment_override_configuration_variable_name="${configuration_variable_name}__override"

	configuration_value="${(P)environment_override_configuration_variable_name}"
}

utils.environment.check.value() {  # support for '.value' : splits between array and scalar
	local configuration_variable_name="${1}"
	local configuration_json="${2}"

	case "$(echo "${configuration_json}" | utils.yq -r '.value | type')" in
		( !!null ) ;;  # no value set
		( !!map  ) ;;  # unsupported type(s)
		( !!seq  )
			local _v
			while IFS= read -r _v
			do
				configuration_values+=("${_v}")
			done < <(echo "${configuration_json}" | utils.yq -r '.value[]')
			;;

		( * ) configuration_value="$(echo "${configuration_json}" | utils.yq -r '.value')" ;;
	esac
}

utils.environment.check.selection() {  # support for '.selection' : configured list prompts user to select a scalar value
	local configuration_variable_name="${1}"
	local configuration_json="${2}"

	local selection_value selection_values=()
	while IFS= read -r selection_value
	do
		selection_values+=("${selection_value}")
	done < <(echo "${configuration_json}" | utils.yq -r ".selection[]" | grep -v '^null$')

	[[ "${#selection_values[@]}" -gt 0 ]] || return

	configuration_value="$(
		printf '%s\n' "${selection_values[@]}" \
			| utils.fzf "select a value for '${configuration_variable_name}'" \
	)"
}
