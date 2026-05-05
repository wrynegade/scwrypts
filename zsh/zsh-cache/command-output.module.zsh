#####################################################################

zsh-cache() {
	local DESCRIPTION='
		Caches the output of any successful shell command for the current
		scwrypts runtime.

		Keep in mind the following:
		    - the --cache-file arg is trusted to be fully unique; running
		      more than one command through the same file will resulted in
		      unexpected behavior

		    - requires computation of a sha1 hash (two in persistent mode),
		      and a write to file on disk/ram; this should only be used for
		      commands which are expensive to compute
	'

	eval "$(utils.parse.autosetup)"
	##########################################

	local DEBUG_ARGS=(
		-v ARGS
		-v cache_file -v cache_file_exists
		-v persistent_cache_get_hash -v persistent_cache_get_hash_args
		-v persistent_cache_hash -v persistent_cache_file
	)
	local TRACE_ARGS=(${(q)DEBUG_ARGS[@]})

	local cache_file_exists \
		&& [[ -f "${cache_file}" ]] \
		&& cache_file_exists=true \
		|| cache_file_exists=false \
		;

	local cache_status
	case "${cache_file_exists}" in
		( true ) cache_status=hit ;;
		( false ) : \
			&& [[ "${persistent_cache_enabled}" == true ]] \
			&& [[ -f "${persistent_cache_file}" ]] \
			&& persistent_cache_hash="$("${persistent_cache_get_hash}" "${persistent_cache_get_hash_args[@]}")" \
			&& [[ "$(head -n1 -- "${persistent_cache_file}")" == "${persistent_cache_hash}" ]] \
			&& cache_status=persistent-hit \
			|| cache_status=miss \
			;;
	esac

	if [[ "${persistent_cache_enabled}" == true ]] && [[ "${cache_status}" == persistent-hit ]]
	then
		[[ "${persistent_cache_hash}" ]] || {
			echo.warning  "persistent cache is enabled, but hash compute failed! persistent cache disabled for this call"
			echo.debug 'hash compute failed'
			persistent_cache_enabled=false
		}
	fi

	case "${cache_status}" in
		( hit )
			echo.trace "$(utils.colors.bright-green)runtime cache hit$(echo.trace.color)"
			;;

		( persistent-hit )
			echo.trace "$(utils.colors.green)persistent cache hit; copying to runtime cache$(echo.trace.color)"
			sed 1d "${persistent_cache_file}" > "${cache_file}"
			;;

		( miss )
			echo.trace "$(utils.colors.yellow)cache miss; running command$(echo.trace.color)"

			local target_cache_file \
				&& [[ "${persistent_cache_enabled}" == true ]] \
				&& target_cache_file="${persistent_cache_file}" \
				|| target_cache_file="${cache_file}" \
				;

			: > "${target_cache_file}"

			[[ "${persistent_cache_enabled}" == true ]] \
				&& echo "${persistent_cache_hash}" >> "${target_cache_file}"

			${ARGS[@]} | grep '.' >> "${target_cache_file}"
			local exit_code="${pipestatus[1]}"

			case "${exit_code}" in
				( 0 )
					[[ "${persistent_cache_enabled}" == true ]] \
						&& sed 1d "${persistent_cache_file}" > "${cache_file}"
					;;

				( * )
					echo.error "command '${ARGS[@]}' failed (or failed to produce output) with exit code ${exit_code}"
					echo.debug "command failed:\n$(cat -- "${target_cache_file}")"
					rm -- "${target_cache_file}"
					return "${exit_code}"
					;;
			esac
	esac

	cat -- "${cache_file}"
}

zsh-cache.parse.locals() {
	local ARGS=()
	local cache_file
	local CACHE_MODE_ARGS_COUNT=0
	local persistent_cache_file
	local persistent_cache_enabled=false
	local persistent_cache_get_hash
	local persistent_cache_get_hash_args=()
	local persistent_cache_hash
	local auto=false
}

zsh-cache.parse.usage() {
	USAGE__options+='
	  --cache-file <string>        runtime-unique filename key for cached data (default: sha1sum of ARGS)
	  --persistent <hash-func>     enables persistence by providing a zsh function to compute the hash
	  -p <argument>                passthrough argument to the get-hash function
	  --persistent-file <string>   overwrite the default persistent filename (default: matches --cache-file)

	  --auto   looks for caller.zsh-cache and, optionally, a caller.zsh-cache.get-hash
	            - -p and args still accepted
	            - when no -p is passed, get-hash will use the same args passed to the zsh-cache function
	'

	USAGE__args+='
	  $1       the command to be cached
	  $2..$N   the arguments for the command to be cached
	'
}

zsh-cache.parse() {
	local parsed=0

	case "${1}" in
		( --cache-file ) parsed=2
			cache_file="${2}"
			;;

		( --persistent-file ) parsed=2
			persistent_cache_file="${2}"
			;;

		( --persistent ) parsed=2
			persistent_cache_enabled=true
			persistent_cache_get_hash="${2}"
			;;

		( -p ) parsed=2
			persistent_cache_get_hash_args+=("${2}")
			;;

		( --auto ) parsed=1; auto=true ;;
	esac

	return "${parsed}"
}

zsh-cache.parse.validate() {
	[[ "${auto}" == true ]] && {
		local caller="${funcstack[5]}"

		command -v "${caller}.zsh-cache" &>/dev/null \
			|| echo.error "--auto mode specified, but couldn't find ${caller}.zsh-cache function"

		[[ "${#ARGS[@]}" -gt 0 ]] \
			&& ARGS=("${caller}.zsh-cache" "${ARGS[@]}") \
			|| ARGS=("${caller}.zsh-cache") \
			;

		command -v "${caller}.zsh-cache.get-hash" &>/dev/null && {
			persistent_cache_enabled=true
			persistent_cache_get_hash="${caller}.zsh-cache.get-hash"

			[[ "${#persistent_cache_get_hash_args[@]}" -eq 0 ]] \
				&& persistent_cache_get_hash_args=("${ARGS[@]:1}")
		}
	}

	[[ "${#ARGS[@]}" -gt 0 ]] \
		|| echo.error "did not specify a command to cache" \
		|| return

	[[ "${cache_file}"            ]] || cache_file="zsh-cache.$(echo "${ARGS[@]}" | utils.sha1sum)"
	[[ "${persistent_cache_file}" ]] || persistent_cache_file="${cache_file}"

	: \
		&& [[ "${cache_file}" ]] \
		&& cache_file="${SCWRYPTS_CACHE_PATH__runtime}/${cache_file}" \
		&& mkdir -p -- "$(dirname -- "${cache_file}")" \
		|| echo.error "must provide valid cache file; cache_file='${cache_file}'" \
		;

	[[ "${CACHE_MODE_ARGS_COUNT}" -le 1 ]] \
		|| echo.error "too many mode arguments specified"

	case "${persistent_cache_enabled}" in
		( false ) ;;
		( true )
			: \
				&& [[ "${persistent_cache_file}" ]] \
				&& persistent_cache_file="${SCWRYPTS_CACHE_PATH__persistent}/${persistent_cache_file}" \
				&& mkdir -p -- "$(dirname -- "${persistent_cache_file}")" \
				|| echo.error "must provide valid persistent cache file; persistent_cache_file='${persistent_cache_file}'" \
				;

			command -v "${persistent_cache_get_hash}" &>/dev/null \
				|| echo.error "invalid hash function '${persistent_cache_get_hash}'" \
				|| return
			;;
	esac
}

#####################################################################

case "$(normalize.boolean --mode export --variable SCWRYPTS__ZSH_CACHE_ENABLED --default true)" in
	( true ) DEPENDENCIES+=(sha1sum) ;;
	( false )
		echo.trace "zsh-cache disabled; mocking module ${scwryptsmodule}"  # see ./zsh-cache.module.zsh

		zsh-cache() {
			local DESCRIPTION="
				cache bypassed with SCWRYPTS__ZSH_CACHE_ENABLED=${SCWRYPTS__ZSH_CACHE_ENABLED}

				instead; this will always execute the forwarded command
			"

			eval "$(zsh.parse.autosetup)"

			##########################################

			${ARGS[@]}
		}

		zsh-cache.parse.validate() {
			case "${auto}" in
				( false ) ;;  # do nothing; ARGS already setup correctly
				( true )
					local caller="${funcstack[5]}"

					command -v "${caller}.zsh-cache" &>/dev/null \
						|| echo.error "--auto mode specified, but couldn't find ${caller}.zsh-cache function"

					[[ "${#ARGS[@]}" -gt 0 ]] \
						&& ARGS=("${caller}.zsh-cache" "${ARGS[@]}") \
						|| ARGS=("${caller}.zsh-cache") \
						;
					;;
			esac
		}
		;;
esac
