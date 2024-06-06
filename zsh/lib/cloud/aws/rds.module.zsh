#####################################################################

DEPENDENCIES+=(docker)
REQUIRED_ENV+=(AWS_ACCOUNT AWS_REGION)

use cloud/aws/cli

#####################################################################

RDS__SELECT_DATABASE() {
	local DATABASES=$(_RDS__GET_AVAILABLE_DATABASES)
	[ ! $DATABASES ] && FAIL 1 'no databases available'

	local ID=$(\
		echo $DATABASES | jq -r '.instance + " @ " + .cluster' \
			| FZF 'select a database (instance@cluster)' \
	)
	[ ! $ID ] && ABORT

	local INSTANCE=$(echo $ID | sed 's/ @ .*$//')
	local CLUSTER=$(echo $ID  | sed 's/^.* @ //')

	echo $DATABASES | jq "select (.instance == \"$INSTANCE\" and .cluster == \"$CLUSTER\")"
}

_RDS__GET_AVAILABLE_DATABASES() {
	AWS rds describe-db-instances \
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

RDS__GET_DATABASE_CREDENTIALS() {
	local PRINT_PASSWORD=0
	local ERRORS=0

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--print-password ) PRINT_PASSWORD=1 ;;
			* )
				WARNING "unrecognized argument $1"
				ERRORS+=1
				;;
		esac
		shift 1
	done

	CHECK_ERRORS

	##########################################

	local DATABASE=$(RDS__SELECT_DATABASE)
	[ ! $DATABASE ] && ABORT

	DB_HOST="$(echo $DATABASE | jq -r '.host')"
	[ ! $DB_HOST ] && { ERROR 'unable to find host'; return 2; }

	DB_PORT="$(echo $DATABASE | jq -r '.port')"
	[ ! $DB_PORT ] && DB_PORT=5432
	[[ $DB_PORT =~ ^null$ ]] && DB_PORT=5432

	##########################################

	local AUTH_METHOD=$(\
		echo "iam\nsecretsmanager\nuser-input" \
			| FZF 'select an authentication method' \
	)
	[ ! $AUTH_METHOD ] && ABORT

	case $AUTH_METHOD in
		iam            ) _RDS_AUTH__iam ;;
		secretsmanager ) _RDS_AUTH__secretsmanager ;;
		user-input     ) _RDS_AUTH__userinput ;;
	esac

	[[ $PRINT_PASSWORD -eq 1 ]] && DEBUG "password : $DB_PASS"

	return 0
}

_RDS_AUTH__iam() {
	DB_PASS=$(\
		AWS rds generate-db-auth-token \
		--hostname $DB_HOST \
		--port $DB_PORT \
		--username $DB_USER \
	)
}

_RDS_AUTH__secretsmanager() {
	local CREDENTIALS=$(_RDS__GET_SECRETSMANAGER_CREDENTIALS)
	echo $CREDENTIALS | jq -e '.pass' >/dev/null 2>&1 \
		&& DB_PASS="$(echo $CREDENTIALS | jq -r '.pass')"

	echo $CREDENTIALS | jq -e '.password' >/dev/null 2>&1 \
		&& DB_PASS="$(echo $CREDENTIALS | jq -r '.password')"

	echo $CREDENTIALS | jq -e '.user' >/dev/null 2>&1 \
		&& DB_USER=$(echo $CREDENTIALS | jq -r '.user')

	echo $CREDENTIALS | jq -e '.username' >/dev/null 2>&1 \
		&& DB_USER=$(echo $CREDENTIALS | jq -r '.username')

	echo $CREDENTIALS | jq -e '.name' >/dev/null 2>&1 \
		&& DB_NAME=$(echo $CREDENTIALS | jq -r '.name')

	echo $CREDENTIALS | jq -e '.dbname' >/dev/null 2>&1 \
		&& DB_NAME=$(echo $CREDENTIALS | jq -r '.dbname')
}

_RDS__GET_SECRETSMANAGER_CREDENTIALS() {
	local ID=$(\
		AWS secretsmanager list-secrets \
			| jq -r '.[] | .[] | .Name' \
			| FZF 'select a secret' \
	)
	[ ! $ID ] && return 1

	AWS secretsmanager get-secret-value --secret-id "$ID" \
		| jq -r '.SecretString' | jq
}

