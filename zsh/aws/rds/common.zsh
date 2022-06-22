_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

__SELECT_CONNECTOR() {
	local DB_TYPE="$1"

	CLIENTS_postgresql=(pgcli psql)

	local C CLIENT=none
	for C in $(eval 'echo $CLIENTS_'$DB_TYPE)
	do
	__CHECK_DEPENDENCY $C >/dev/null 2>&1 && {
		CLIENT=$C
		__STATUS "detected '$CLIENT' for $DB_TYPE"
		break
	}
	done

	echo $CLIENT
}
