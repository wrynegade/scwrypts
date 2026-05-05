utils.dependencies.check-all() {
	local ERRORS=0
	[[ "${SCWRYPTS_LOG_LEVEL}" ]] || local SCWRYPTS_LOG_LEVEL=1

	DEPENDENCIES+=(sed awk grep find readlink)
	DEPENDENCIES=($(echo ${DEPENDENCIES[@]} | sed 's/ \+/\n/g' | sort -u))

	local dependency
	for dependency in ${DEPENDENCIES[@]}
	do
		utils.dependencies.check "${dependency}" || ((ERRORS+=1))
	done

	return ${ERRORS}
}

utils.dependencies.check() {
	local ERRORS=0

	local dependency
	local dependency_default_args=()
	local dependency_required=true

	local _s _p
	while [[ "${#}" -gt 0 ]]
	do
		_s=1
		case "${1}" in
			( --optional ) dependency_required=false ;;
			( * )
				case $((_p+=1)) in
					( 1 ) dependency="${1}" ;;
					( * ) dependency_default_args+=("${1}") ;;
				esac
		esac
		shift ${_s} || echo.error "missing required argument for '${1}'" || shift "${#}"
	done
	unset _s _p

	[[ "${dependency}" ]] || echo.error 'no dependency specified'

	[[ "${ERRORS}" -eq 0 ]] || return "${ERRORS}"

	##########################################

	local executable_path="$(command -v "${dependency}" 2>/dev/null)"
	[[ "${executable_path}" ]] || {
		case "${dependency_required}" in
			( true  ) echo.error   "application '${dependency}' required but not available on PATH" ;;
			( false ) echo.warning "application '${dependency}' preferred but not available on PATH" ;;
		esac

		local credits="$(utils.dependencies.credits "${dependency}")"
		[[ "${credits}" ]] && echo.reminder "${credits}"

		return 1
	}
	[[ "${dependency}" =~ "^${executable_path}$" ]] && {
		# echo "built-in '${dependency}' cannot be wrapped for safety" >&2
		return 0
	}

	local automatic_trace=true
	local extra_eval_statements=''

	case "${dependency}" in
		( yq )
			yq --version | grep -q mikefarah \
				|| echo.warning 'detected kislyuk/yq but mikefarah/yq is required'
			;;

		( awk | sed | grep | find | readlink )
			automatic_trace=false
			"${executable_path}" --version 2>&1 | grep 'GNU' | grep -qv 'BSD' || {
				executable_path="$(command -v g${dependency})"
				[[ "${executable_path}" ]] \
					|| echo.error "unable to locate GNU ${dependency}; if you're on MacOS you may need to install the appropriate gnu-${dependency} package"
			}
			;;

		( gawk | gsed | ggrep | gfind | greadlink )
			echo.error "do not use MacOS / BSD shadows for utilities which require GNU (use ${dependency/g/} instead)"
			;;

		( aws | eksctl )
			extra_eval_statements+="
				echo.warning  'use of ${dependency} directly is highly discouraged; utilize appropriate module instead'
			"
			case "${dependency}" in
				( aws ) extra_eval_statements+="echo.reminder 'use cloud/aws/cli : cloud.aws.cli'" ;;
				( *   ) extra_eval_statements+="echo.reminder 'use cloud/aws/${dependency} : cloud.aws.${dependency}'" ;;
			esac
			;;
	esac || return "${ERRORS}"

	eval "${dependency}() {
		local DEBUG_ARGS=() TRACE_ARGS=() ERRORS=0 WARNINGS=0
		local default_args=(${(q)dependency_default_args[@]})
		local print_trace=${automatic_trace}
		local args=()

		while [[ \${#} -gt 0 ]]
		do
			case \${1} in
				( --omit-default-args )
					default_args=()
					;;

				( --no-scwrypts-trace )
					print_trace=false
					;;

				( --force-scwrypts-trace )
					print_trace=true
					;;

				( * ) args+=(\"\${1}\") ;;
			esac
			shift 1
		done

		[[ \"\${print_trace}\" =~ true ]] && echo.trace \"${(q-)executable_path} \${(q-)default_args[@]} \${(q-)args[@]}\"

		${extra_eval_statements}

		'${executable_path}' \"\${default_args[@]}\" \"\${args[@]}\"
	}"
}

utils.dependencies.credits() {
	return 0
	# scwrypts exclusive ("credits" pulled from README files)
	[ ! ${__SCWRYPT} ] && return 0

	local COMMAND="$1"
	[[ $COMMAND =~ - ]] && COMMAND=$(echo $COMMAND | sed 's/-/--/g')
	(
	cd "$(scwrypts.config.group scwrypts root)"
	cat ./**/README.md \
		| grep 'Generic Badge' \
		| sed -n "s/.*Generic Badge.*-$COMMAND-.*(/(/p" \
		;
	)
}
