_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################


GET_POSTGRES_LOGIN_ARGS() {
	while [[ $# -gt 0 ]]
	do
		case $1 in
			--host | -h ) _HOST="$2"; shift 2 ;;
			--name | -d ) _NAME="$2"; shift 2 ;;
			--pass | -w ) _PASS="$2"; shift 2 ;;
			--port | -p ) _PORT="$2"; shift 2 ;;
			--user | -U ) _USER="$2"; shift 2 ;;
			* ) shift 1 ;;
		esac
	done

	[ ! $_HOST ] && _HOST=127.0.0.1
	[ ! $_NAME ] && _NAME=postgres
	[ ! $_PORT ] && _PORT=5432
	[ ! $_USER ] && _USER=postgres
}
