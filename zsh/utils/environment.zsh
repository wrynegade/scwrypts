utils.environment.check-all() {
	# checks all environment variables in REQUIRED_ENV=()
	local SCWRYPTS_LOG_LEVEL=4
	local VAR ERRORS=0

	REQUIRED_ENV=($(echo ${REQUIRED_ENV} | sed 's/\s\+/\n/g' | sort --unique))

	for VAR in ${REQUIRED_ENV[@]}; do utils.environment.check ${VAR} || ((ERRORS+=1)); done

	return ${ERRORS}
}

utils.environment.check() {
	local NAME OPTIONAL DEFAULT_VALUE LOOKUP_PATH
	local NAME_IS=environment-variable
	local PRINT_VALUE=false

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

	local _S ERRORS=0 POSITIONAL_ARGS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			-h | --help )
				utils.io.usage
				return 0
				;;

			--optional )
				OPTIONAL=true
				;;

			--print-value )
				PRINT_VALUE=true
				;;

			--default )
				[ $2 ] && ((_S+=1)) \
					|| echo.error "missing env var default value" \
					|| break

				[ ! "${DEFAULT_VALUE}" ] \
					|| echo.error "only one default value is supported" \
					|| break

				[[ ${OPTIONAL} =~ true ]] \
					&& echo.warning "--optional and --default flags are redundant; remove '--optional' flag"

				DEFAULT_VALUE="$2"
				OPTIONAL=true
				;;

			* )
				((POSITIONAL_ARGS+=1))
				case ${POSITIONAL_ARGS} in
					1 ) NAME="$1"
						;;

					2 ) DEFAULT_VALUE="$1"
						echo.warning "use of positional argument for default value is DEPRECATED\nplease use --default <value> flag"
						;;

					* ) echo.error "unknown argument '$1'"
						;;
				esac
				;;
		esac
		shift ${_S}
	done

	[ "${NAME}" ] \
		|| echo.error "must provide environment variable name"

	[ "${OPTIONAL}" ] || OPTIONAL=false

	echo "${NAME}" | grep -q '^\.' \
		&& NAME_IS=lookup-path

	case ${NAME_IS} in
		lookup-path )
			[ ${__SCWRYPT} ] || echo.error "lookup paths cannot be used outside of scwrypts (${NAME})"
			[ ${__SCWRYPT} ] && {
				use scwrypts/environment \
					|| echo.error "unable to load lookup path"

				LOOKUP_PATH="${NAME}"
				NAME=$(\
					scwrypts.environment.get-full-template \
						| utils.yq -r "${LOOKUP_PATH}.\".ENVIRONMENT\"" \
						| grep -v ^null$\
					)

				[ ${NAME} ] || echo.error "no .ENVIRONMENT key is configured for '${LOOKUP_PATH}'"
			}
			;;
		environment-variable )
			;;
	esac

	utils.check-errors --no-fail --no-usage || return $?

	##########################################

	# only check env vars once
	local ALREADY_CHECKED="$(eval echo '$'${NAME}'__checked')"
	[ "${ALREADY_CHECKED}" ] && return ${ALREADY_CHECKED}

	[ ${__SCWRYPT} ] || local CI=true  # outside of scwrypts, environment must load like CI runtime
	[ ${CI} ] && {
		echo doing the ci thing >&2
		local VALUE="$(eval echo '$'${NAME})"
		[ "${VALUE}" ] && {
			export ${NAME}__checked=0
			[[ ${PRINT_VALUE} =~ true ]] && echo "${VALUE}"
			return 0
		}

		case ${OPTIONAL} in
			true )
				[ "${DEFAULT_VALUE}" ] \
					&& export ${NAME}=${DEFAULT_VALUE} \
					|| echo.warning "environment variable '${NAME}' is not set" \
					;

				export ${NAME}__checked=0
				return 0
				;;
			false )
				local ERROR_MESSAGE="missing required environment variable '${NAME}'"
				[ "${LOOKUP_PATH}" ] && ERROR_MESSAGE+=" (config path '${LOOKUP_PATH}')"

				echo.error "${ERROR_MESSAGE}"
				export ${NAME}__checked=1
				return 1
				;;
		esac
	}

	[ ! ${LOOKUP_PATH} ] && {
		LOOKUP_PATH="$(scwrypts.environment.get-envvar-lookup-map | utils.yq -r ".${NAME}" | sed 's/\.value$//')"
	}

	# ensure environment safety; prevent bleed in from user's runtime
	unset ${NAME}
	local VALUE
	for GET_VALUE_METHOD in \
		runtimeoverride \
		value \
		selection \
		select \
		;
	do
		VALUE=$(utils.environment.check.${GET_VALUE_METHOD} "${NAME}" "${LOOKUP_PATH}")
		[ "${VALUE}" ] && eval "export ${NAME}=${VALUE}" && break
	done

	[ "${VALUE}" ] && {
		export ${NAME}__checked=0
		[[ ${PRINT_VALUE} =~ true ]] && echo "${VALUE}"
		return 0
	}

	case ${OPTIONAL} in
		true )
			[ "${DEFAULT_VALUE}" ] \
				&& export ${NAME}=${DEFAULT_VALUE} \
				|| echo.warning "environment variable '${NAME}' is not set" \
				;

			export ${NAME}__checked=0
			return 0
			;;
		false )
			local ERROR_MESSAGE="missing required environment variable '${NAME}'"
			[ "${LOOKUP_PATH}" ] && ERROR_MESSAGE+=" (config path '${LOOKUP_PATH}')"

			echo.error "${ERROR_MESSAGE}"
			export ${NAME}__checked=1
			return 1
			;;
	esac
}

utils.environment.check.runtimeoverride() {
	local NAME="$1"
	local LOOKUP_PATH="$2"
	eval echo '$'${NAME}'__override'
}

utils.environment.check.value() {
	local NAME="$1"
	local LOOKUP_PATH="$2"

	scwrypts.environment.user.get-shell-values \
		| utils.yq -r "${LOOKUP_PATH}.value" \
		| grep -v '^null$' \
		;
}

utils.environment.check.selection() {
	local NAME="$1"
	local LOOKUP_PATH="$2"

	local SELECTION_VALUES=($(
		scwrypts.environment.user.get-shell-values \
			| utils.yq -r "${LOOKUP_PATH}.selection[]" \
			| grep -v '^null$' \
			))

	[[ ${#SELECTION_VALUES[@]} -gt 0 ]] || return

	echo "${SELECTION_VALUES}" \
		| sed 's/\s\+/\n/g' \
		| utils.fzf "select a value for '${NAME}'" \
		;
}

utils.environment.check.select() {  # support for ENV_VAR__select=()
	local NAME="$1"
	local LOOKUP_PATH="$2"

	local SELECTION_VALUES=($(eval echo '$'${NAME}'__select'))

	[[ ${#SELECTION_VALUES[@]} -gt 0 ]] || return

	echo.warning "support for ENV_VAR__select syntax is deprecated;\nplease use the .selection[] array in the yaml configuration for user-selectable options"

	echo "${SELECTION_VALUES}" \
		| sed 's/\s\+/\n/g' \
		| utils.fzf "select a value for '${NAME}'" \
		;
}
