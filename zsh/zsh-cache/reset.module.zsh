#####################################################################

${scwryptsmodule}.all() {
	local ERRORS=0

	local cache_type
	for cache_type in persistent runtime
	do
		zsh-cache.reset.${cache_type} || ((ERRORS+=1))
	done

	return "${ERRORS}"
}

${scwryptsmodule}.persistent() { zsh-cache.reset._ persistent; }
${scwryptsmodule}.runtime()    { zsh-cache.reset._ runtime;    }

${scwryptsmodule}._() {
	local ERRORS=0
	local TRACE_ARGS=(-v cache_variable -v cache_path)

	local cache_variable cache_path cache_name="${1}"
	case "${cache_name}" in
		( persistent | runtime )
			cache_variable="SCWRYPTS_CACHE_PATH__${cache_name}"
			cache_path="${(P)cache_variable}"

			[[ "${cache_path}" ]] \
				|| echo.error "could not discover cache path; is ${cache_variable} set?" \
				|| return 1
			;;
		( * )
			echo.error "invalid cache '${cache_name}'"
			return 1
			;;
	esac

	if [[ -d "${cache_path}" ]]
	then
		echo.trace "deleting cache directory"
		rm -rf -- "${cache_path}" \
			|| echo.error "failed to delete cache directory for ${cache_name}"
	fi

	echo.trace "recreating cache directory"
	mkdir -p -- "${cache_path}" \
		|| echo.error "failed to recreate cache path for ${cache_name}"

	[[ "${ERRORS}" -eq 0 ]] \
		&& echo.success "successfully cleared ${cache_name} cache"

	return "${ERRORS}"
}

#####################################################################
case "$(normalize.boolean --mode export --variable SCWRYPTS__ZSH_CACHE_ENABLED --default true)" in
	( true ) ;;
	( false )
		echo.trace "zsh-cache disabled; mocking module ${scwryptsmodule}"  # see ./zsh-cache.module.zsh

		for _PROVIDED_FUNCTION in all persistent runtime
		do
			${scwryptsmodule}.${_PROVIDED_FUNCTION}() {
				local WARNINGS=0
				echo.warning "cache is disabled; skipping reset request"
				return 0
			}
		done

		unset _PROVIDED_FUNCTION
		;;
esac
