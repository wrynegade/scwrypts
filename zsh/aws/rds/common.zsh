_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

GET_DATABASE_CREDENTIALS() {
	local PRINT_PASSWORD=0
	local ERRORS=0

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--print-password ) PRINT_PASSWORD=1 ;;
			* )
				__WARNING "unrecognized argument $1"
				ERRORS+=1
				;;
		esac
		shift 1
	done

	__ERROR_CHECK

	##########################################

	local DATABASE=$(SELECT_DATABASE)
	[ ! $DATABASE ] && __ABORT

	DB_HOST="$(echo $DATABASE | jq -r '.host')"
	[ ! $DB_HOST ] && { __ERROR 'unable to find host'; return 2; }

	DB_PORT="$(echo $DATABASE | jq -r '.port')"
	[ ! $DB_PORT ] && DB_PORT=5432
	[[ $DB_PORT =~ ^null$ ]] && DB_PORT=5432

	##########################################

	local AUTH_METHOD=$(\
		echo "iam\nsecretsmanager\nuser-input" \
			| __FZF 'select an authentication method' \
	)
	[ ! $AUTH_METHOD ] && __ABORT

	case $AUTH_METHOD in
		iam            ) GET_AUTH__IAM ;;
		secretsmanager ) GET_AUTH__SECRETSMANAGER ;;
		user-input     ) GET_AUTH__USER_INPUT ;;
	esac

	__STATUS
	__STATUS "host     : $DB_HOST"
	__STATUS "type     : $DB_TYPE"
	__STATUS "port     : $DB_PORT"
	__STATUS "database : $DB_NAME"
	__STATUS "username : $DB_USER"
	[[ $PRINT_PASSWORD -eq 1 ]] && __STATUS "password : $DB_PASS"
	__STATUS
}

GET_AUTH__IAM() {
	DB_PASS=$(\
		_AWS rds generate-db-auth-token \
		--hostname $DB_HOST \
		--port $DB_PORT \
		--username $DB_USER \
	)
}

GET_AUTH__SECRETSMANAGER() {
	local CREDENTIALS=$(GET_SECRETSMANAGER_CREDENTIALS)
	echo $CREDENTIALS | jq -e '.pass' >/dev/null 2>&1 \
		&& DB_PASS="'$(echo $CREDENTIALS | jq -r '.pass' | sed "s/'/'\"'\"'/g")'"
	
	echo $CREDENTIALS | jq -e '.password' >/dev/null 2>&1 \
		&& DB_PASS="'$(echo $CREDENTIALS | jq -r '.password' | sed "s/'/'\"'\"'/g")'"
	
	echo $CREDENTIALS | jq -e '.user' >/dev/null 2>&1 \
		&& DB_USER=$(echo $CREDENTIALS | jq -r '.user')
	
	echo $CREDENTIALS | jq -e '.username' >/dev/null 2>&1 \
		&& DB_USER=$(echo $CREDENTIALS | jq -r '.username')
	
	echo $CREDENTIALS | jq -e '.name' >/dev/null 2>&1 \
		&& DB_NAME=$(echo $CREDENTIALS | jq -r '.name')
	
	echo $CREDENTIALS | jq -e '.dbname' >/dev/null 2>&1 \
		&& DB_NAME=$(echo $CREDENTIALS | jq -r '.dbname')
}

GET_SECRETSMANAGER_CREDENTIALS() {
	local ID=$(\
		_AWS secretsmanager list-secrets \
			| jq -r '.[] | .[] | .Name' \
			| __FZF 'select a secret' \
	)
	[ ! $ID ] && return 1

	_AWS secretsmanager get-secret-value --secret-id "$ID" \
		| jq -r '.SecretString' | jq
}

SELECT_DATABASE() {
	local DATABASES=$(GET_AVAILABLE_DATABASES)
	[ ! $DATABASES ] && __FAIL 1 'no databases available'

	local ID=$(\
		echo $DATABASES | jq -r '.instance + " @ " + .cluster' \
			| __FZF 'select a database (instance@cluster)' \
	)
	[ ! $ID ] && __ABORT

	local INSTANCE=$(echo $ID | sed 's/ @ .*$//')
	local CLUSTER=$(echo $ID  | sed 's/^.* @ //')

	echo $DATABASES | jq "select (.instance == \"$INSTANCE\" and .cluster == \"$CLUSTER\")"
}

GET_AVAILABLE_DATABASES() {
	_AWS rds describe-db-instances \
		| jq -r '.[] | .[] | {
			instance: .DBInstanceIdentifier,
			cluster:  .DBClusterIdentifier,
			type:     .Engine,
			host:     .Endpoint.Address,
			port:     .Endpoint.Port,
			user:     .MasterUsername,
			database: .DBName
		}'
}

