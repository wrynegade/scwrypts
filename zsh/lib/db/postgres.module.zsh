#####################################################################

DEPENDENCIES+=(
	pg_dump
	pg_restore
	psql
	pgcli
)

REQUIRED_ENV+=()

#####################################################################

PSQL() {
	[[ ${#ARGS[@]} -eq 0 ]] && POSTGRES__SET_LOGIN_ARGS $@

	eval PGPASSWORD=$_PASS psql ${_ARGS[@]}
}

#####################################################################

PG_DUMP() {
	local _HOST _NAME _PORT _USER _FILE
	local DATA_DIR _PASS _ARGS=()
	POSTGRES__SET_LOGIN_ARGS --verbose $@

	local OUTPUT_FILE="$DATA_DIR/backup.$(date '+%Y-%m-%d.%H-%M')"

	STATUS "
	making backup of : $_USER@$_HOST:$_PORT/$_NAME

	    (compressed) : '$OUTPUT_FILE.dump'
	      (safe-raw) : '$OUTPUT_FILE.sql'
	           (raw) : '$OUTPUT_FILE.raw.sql'
	"

	: \
		&& STATUS "creating compressed backup..." \
		&& eval PGPASSWORD=$_PASS pg_dump ${_ARGS[@]} --format custom --file "$OUTPUT_FILE.dump" \
		&& SUCCESS "completed compressed backup" \
		&& STATUS "creating raw backup..." \
		&& eval PGPASSWORD=$_PASS pg_dump ${_ARGS[@]} > "$OUTPUT_FILE.raw.sql" \
		&& SUCCESS "completed raw backup" \
		&& STATUS "creating single-transaction raw backup..." \
		&& { echo "BEGIN;"; cat "$OUTPUT_FILE.raw.sql"; echo "END;" } > "$OUTPUT_FILE.sql" \
		&& SUCCESS "completed single-transaction raw backup" \
		|| { ERROR "error creating backup for '$_HOST/$_NAME' (see above)"; return 1; }
}

#####################################################################

PG_RESTORE() {
	local _HOST _NAME _PORT _USER
	local _PASS _ARGS=()
	local _FILE
	POSTGRES__SET_LOGIN_ARGS $@

	local INPUT_FILE=$(find "$DATA_DIR"/backup.* -type f | FZF 'select database file to restore')

	[ $INPUT_FILE ] && [ -f "$INPUT_FILE" ] || {
		ERROR 'no file selected or missing backup file; aborting'
		REMINDER "
			backups must be *.sql or *.dump files starting with the prefix 'backup.'
			in the following directory:

			'$DATA_DIR'
		"
		return 1
	}

	local RAW=1
	[[ $INPUT_FILE =~ \\.dump$ ]] && RAW=0

	STATUS "
	loading backup for : $_USER@$_HOST:$_PORT/$_NAME

	              file : '$INPUT_FILE'
	"

	local EXIT_CODE
	[[ $RAW -eq 1 ]] && {
		REMINDER "
			loading a backup from a raw sql dump may result in data loss

			make sure your database is ready to accept the database file!
		"

		yN 'continue?' || ABORT

		PSQL < "$INPUT_FILE"
		EXIT_CODE=$?
	}

	[[ $RAW -eq 0 ]] && {
		PGPASSWORD="$_PASS" pg_restore ${_ARGS[@]} \
			--verbose \
			--format custom \
			--single-transaction \
			"$INPUT_FILE"
		EXIT_CODE=$?
	}

	[[ $EXIT_CODE -eq 0 ]] \
		&& SUCCESS "finished restoring backup for '$_HOST/$_NAME'" \
		|| ERROR "error restoring backup for '$_HOST/$_NAME' (see above)" \
		;

	return $EXIT_CODE
}

#####################################################################

POSTGRES__LOGIN_INTERACTIVE() {
	local _PASS _ARGS=()
	POSTGRES__SET_LOGIN_ARGS $@

	STATUS "performing login  : $_USER@$_HOST:$_PORT/$_NAME"
	STATUS "working directory : $DATA_DIR"

	eval PGPASSWORD=$_PASS pgcli ${_ARGS[@]}
}

#####################################################################

POSTGRES__SET_LOGIN_ARGS() {
	while [[ $# -gt 0 ]]
	do
		case $1 in
			--host ) _ARGS+=(-h $2); _HOST="$2"; shift 1 ;;
			--name ) _ARGS+=(-d $2); _NAME="$2"; shift 1 ;;
			--port ) _ARGS+=(-p $2); _PORT="$2"; shift 1 ;;
			--user ) _ARGS+=(-U $2); _USER="$2"; shift 1 ;;

			--pass ) _PASS="$2"; shift 1 ;;

			--file ) _FILE="$2"; shift 1 ;;

			* ) _ARGS+=($1) ;;
		esac
		shift 1
	done

	[ $_FILE ] && [ ! -f "$_FILE" ] && {
		ERROR "no such file '$_FILE'"
		exit 1
	}

	[ $_HOST ] && [ $_NAME ] \
		&& DATA_DIR="$SCWRYPTS_DATA_PATH/db/$_HOST/$_NAME" \
		|| DATA_DIR="$EXECUTION_DIR/temp-db" \
		;

	[ ! -d "$DATA_DIR" ] && mkdir -p "$DATA_DIR"
	cd "$DATA_DIR"

	return 0
}

