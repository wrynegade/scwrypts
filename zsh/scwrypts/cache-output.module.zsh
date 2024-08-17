${scwryptsmodule}() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		Caches any successful shell operation for the current scwrypts runtime;
		useful for operations which require heavy processing, but frequent access.

		Keep in mind the following:
			- Operations are hashed exclusively by the --cache-file argument; use of the
			  same cache file for multiple different commands will result in erratic behavior,
			  so make sure the filename is unique across the full scwrypts runtime

			- Operations which have a failed shell exit code are not cached; operations
			  MUST succeed the first time in order to be cached

			- The full stdout of the operation is cached to RAM
	"

	local \
		USE_CACHE=true CACHE_ARGS_COUNT=0 CACHE_FILE \
		ARGS=() ARGS_FORCE=allowed \
		;

	eval "$ZSHPARSEARGS"

	local CACHE_FILE_FULLPATH="$SCWRYPTS_TEMP_PATH/$CACHE_FILE"

	case $USE_CACHE in
		bypass ) ${ARGS[@]} ;;
		true | reset )
			local EXIT_CODE=0

			[[ $USE_CACHE =~ reset ]] && rm -- "$CACHE_FILE_FULLPATH" &>/dev/null

			[ -f "$CACHE_FILE_FULLPATH" ] || {
				${ARGS[@]} > "$CACHE_FILE_FULLPATH"
				EXIT_CODE=$?
			}

			case $EXIT_CODE in
				0 ) cat "$CACHE_FILE_FULLPATH"
					;;
				* ) cat "$CACHE_FILE_FULLPATH" 2>/dev/null
					ERROR "error running '${ARGS[@]}'"
					rm -- "$CACHE_FILE_FULLPATH" &>/dev/null
					;;
			esac

			return $EXIT_CODE
			;;
	esac
}

#####################################################################

${scwryptsmodule}.parse() {
	# local USE_CACHE CACHE_ARGS_COUNT=0 CACHE_FILE
	local PARSED=0
	case $1 in
		--use-cache )
			PARSED=2
			case $2 in
				true | reset | bypass )
					((CACHE_ARGS_COUNT+=1))
					USE_CACHE=$2
					;;
				* ) ERROR "cannot set USE_CACHE to '$2'" ;;
			esac
			;;

		--cache-file )
			PARSED=2
			CACHE_FILE=$2
			;;
	esac
	return $PARSED
}

${scwryptsmodule}.parse.usage() {
	USAGE__options+="\n
		--cache-file   (required) runtime-unique filename for cached data
		               for cache to be automatically cleared, make sure this is a simple filename (no directories)

		--reset-cache    clear the cache before performing the operation
		--bypass-cache   skip the cache for a clean operation, but don't clear existing or set new cache data
	"

	USAGE__args+="\n
		remaining arguments are executed as a shell command
	"
}

${scwryptsmodule}.parse.validate() {
	case $USE_CACHE in
		true | reset | bypass ) ;;
		* ) ERROR "invalid value '$USE_CACHE' for USE_CACHE (are you missing 'local USE_CACHE=true'?)" ;;
	esac

	[[ "$CACHE_FILE" ]] && {
		mkdir -p -- "$SCWRYPTS_TEMP_PATH/$(dirname -- "$CACHE_FILE")" \
			|| ERROR "unable to create base directory '$SCWRYPTS_TEMP_PATH/$(dirname -- "$CACHE_FILE")'"

		true
	} || ERROR "missing cache file"

	[[ ${#ARGS[@]} -gt 0 ]] \
		|| ERROR "no command provided"

	[[ $CACHE_ARGS_COUNT -le 1 ]] \
		|| ERROR "too many '--use-cache' flags used"
}

#####################################################################

${scwryptsmodule}.parsers.args() {
	# local CACHE_ARGS=()
	local PARSED=0
	case $1 in
		--use-cache )
			PARSED=2
			case $2 in
				true | reset | bypass )
					CACHE_ARGS+=(--use-cache $2)
					;;

				* ) ERROR "invalid --use-cache value '$2'" ;;
			esac
	esac
	return $PARSED
}

${scwryptsmodule}.parsers.args.usage() {
	USAGE__options+="\n
		--use-cache   (default true) one of {'true', 'reset', 'bypass'}
	"

	USAGE__description+="\n
		(this function uses functions cached per scwrypts runtime)
	"
}

#####################################################################
