#####################################################################

${scwryptsmodule}() {
	utils.dependencies.check redis-cli || return 1

	local USE_DEFAULT_CREDENTIALS=true ARGS PARSERS=()

	eval "$ZSHPARSEARGS"

	redis-cli ${#ARGS[@]}
}

#####################################################################

${scwryptsmodule}.parse() {
	# local USE_DEFAULT_CREDENTIALS=true ARGS=()
	local PARSED=0

	case $1 in
		( --host ) PARSED=2; USE_DEFAULT_CREDENTIALS=false; ARGS+=(-h $2) ;;
		( --port ) PARSED=2; USE_DEFAULT_CREDENTIALS=false; ARGS+=(-p $2) ;;
		( --auth ) PARSED=2; USE_DEFAULT_CREDENTIALS=false; ARGS+=(-a $2) ;;
		( * ) PARSED=1; ARGS+=($1) ;;
	esac

	return $PARSED
}

${scwryptsmodule}.parse.usage() {
	USAGE__options="
		--host <string>   address of redis host
		--port <string>   (default = 6379) access port for redis service
		--auth <string>   (optional) connection password

		(additional arguments and options are forwarded to redis-cli)
	"
}

${scwryptsmodule}.parse.validate() {
	[[ ${USE_DEFAULT_CREDENTIALS} =~ true ]] && {
		utils.environment.check REDIS_HOST &>/dev/null \
			|| echo.error "must set REDIS_HOST" \
			;

		utils.environment.check REDIS_PORT --default 6379 &>/dev/null
		utils.environment.check REDIS_AUTH --optional &>/dev/null

		ARGS+=(-h "${REDIS_HOST}" -p "${REDIS_PORT}")
		[ "${REDIS_AUTH}" ] && ARGS+=(-a "${REDIS_AUTH}")
	}
}
