#####################################################################

DEPENDENCIES+=(
	redis-cli
)

REQUIRED_ENV+=()

#####################################################################

REDIS() {
	[[ ${#ARGS[@]} -eq 0 ]] && REDIS__SET_LOGIN_ARGS $@

	redis-cli ${#ARGS[@]}
}


REDIS__SET_LOGIN_ARGS() {
	while [[ $# -gt 0 ]]
	do
		case $1 in
			--host ) _ARGS+=(-h $2); _HOST="$2"; shift 1 ;;
			--port ) _ARGS+=(-p $2); _PORT="$2"; shift 1 ;;
			--pass ) _ARGS+=(-a $2); _PASS="$2"; shift 1 ;;

			--file ) _FILE="$2"; shift 1 ;;

			* ) _ARGS+=($1) ;;
		esac
		shift 1
	done

	[ $_FILE ] && [ ! -f "$_FILE" ] && {
		echo.error "no such file '$_FILE'"
		exit 1
	}

	return 0
}

REDIS__ENABLED() {
	REDIS ping 2>&1 | grep -qi pong
}
