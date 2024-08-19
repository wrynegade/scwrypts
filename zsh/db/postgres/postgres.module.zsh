#####################################################################

DEPENDENCIES+=(
	pg_dump
	pg_restore
	psql
)

REQUIRED_ENV+=()

#####################################################################

PSQL() {
	POSTGRES__SET_LOGIN_ARGS $@
	eval PGPASSWORD=$(printf '%q ' "$DB_PASS") psql ${PSQL_ARGS[@]}
}

#####################################################################

PG_DUMP() {
	local DATA_DIR
	POSTGRES__SET_LOGIN_ARGS --verbose $@

	local OUTPUT_FILE="$DATA_DIR/backup.$(date '+%Y-%m-%d.%H-%M')"



	echo.status "
	making backup of : $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME

	    (compressed) : '$OUTPUT_FILE.dump'
	      (safe-raw) : '$OUTPUT_FILE.sql'
	           (raw) : '$OUTPUT_FILE.raw.sql'
	"

	: \
		&& echo.status "creating compressed backup..." \
		&& eval PGPASSWORD=$(printf '%q ' "$DB_PASS") psql ${PSQL_ARGS[@]} \
			--format custom \
			--file "$OUTPUT_FILE.dump" \
			--verbose \
		&& echo.success "completed compressed backup" \
		&& echo.status "creating raw backup..." \
		&& pg_restore -f "$OUTPUT_FILE.raw.sql" "$OUTPUT_FILE.dump" \
		&& echo.success "completed raw backup" \
		&& echo.status "creating single-transaction raw backup..." \
		&& { echo "BEGIN;\n"; cat "$OUTPUT_FILE.raw.sql"; echo "\nEND;" } > "$OUTPUT_FILE.sql" \
		&& echo.success "completed single-transaction raw backup" \
		|| { echo.error "error creating backup for '$DB_HOST/$DB_NAME' (see above)"; return 1; }

	echo.success "
	completed backup : $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME

	    (compressed) : '$OUTPUT_FILE.dump'
	      (safe-raw) : '$OUTPUT_FILE.sql'
	           (raw) : '$OUTPUT_FILE.raw.sql'
	 "
}

#####################################################################

PG_RESTORE() {
	local _ARGS=()
	local FILE
	POSTGRES__SET_LOGIN_ARGS $@

	local INPUT_FILE=$(find "$DATA_DIR"/backup.* -type f | FZF 'select database file to restore')

	[ $INPUT_FILE ] && [ -f "$INPUT_FILE" ] || {
		echo.error 'no file selected or missing backup file; aborting'
		echo.reminder "
			backups must be *.sql or *.dump files starting with the prefix 'backup.'
			in the following directory:

			'$DATA_DIR'
		"
		return 1
	}

	local RAW=1
	[[ $INPUT_FILE =~ \\.dump$ ]] && RAW=0

	echo.status "
	loading backup for : $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME

	              file : '$INPUT_FILE'
	"

	local EXIT_CODE
	[[ $RAW -eq 1 ]] && {
		echo.reminder "
			loading a backup from a raw sql dump may result in data loss

			make sure your database is ready to accept the database file!
		"

		yN 'continue?' || ABORT

		PSQL < "$INPUT_FILE"
		EXIT_CODE=$?
	}

	[[ $RAW -eq 0 ]] && {
		eval PGPASSWORD=$(printf '%q ' "$DB_PASS") pg_restore ${PSQL_ARGS[@]} \
			--verbose \
			--format custom \
			--single-transaction \
			"$INPUT_FILE"
		EXIT_CODE=$?
	}

	[[ $EXIT_CODE -eq 0 ]] \
		&& echo.success "finished restoring backup for '$DB_HOST/$DB_NAME'" \
		|| echo.error "error restoring backup for '$DB_HOST/$DB_NAME' (see above)" \
		;

	return $EXIT_CODE
}

#####################################################################

POSTGRES__LOGIN_INTERACTIVE() {
	DEPENDENCIES=(pgcli) CHECK_ENVIRONMENT --optional \
		&& COMMAND=pgcli || COMMAND=psql

	[[ $COMMAND =~ psql ]] && echo.warning "using 'psql' instead"

	POSTGRES__SET_LOGIN_ARGS $@

	echo.status "
	performing login  : $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME
	working directory : $DATA_DIR
	 "

	eval PGPASSWORD=$(printf '%q ' "$DB_PASS") $COMMAND ${PSQL_ARGS[@]}
}

#####################################################################

POSTGRES__SET_LOGIN_ARGS() {
	# allow for manual override with PSQL_ARGS
	[[ ${#PSQL_ARGS[@]} -gt 0 ]] && return 0

	local DATA_DIR_PREFIX

	while [[ $# -gt 0 ]]
	do
		case $1 in
			-h | --host ) DB_HOST="$2"; shift 1 ;;
			-p | --port ) DB_PORT="$2"; shift 1 ;;
			-d | --name ) DB_NAME="$2"; shift 1 ;;
			-U | --user ) DB_USER="$2"; shift 1 ;;
			-P | --pass ) DB_PASS="$2"; shift 1 ;;

			--file  ) PSQL_FILE="$2";  shift 1 ;;

			--data-dir-prefix ) DATA_DIR_PREFIX="$2"; shift 1 ;;

			* ) PSQL_ARGS+=($1) ;;
		esac
		shift 1
	done

	[ $PSQL_FILE ] && [ ! -f "$PSQL_FILE" ] \
		&& echo.error "no such file available:\n'$PSQL_FILE'"

	CHECK_ERRORS

	##########################################

	[ $DATA_DIR_PREFIX ] && {
		DATA_DIR="$SCWRYPTS_DATA_PATH/$DATA_DIR_PREFIX"
	} || {
		[ $DB_HOST ] && [ $DB_NAME ] \
			&& DATA_DIR="$SCWRYPTS_DATA_PATH/db/$DB_HOST/$DB_NAME" \
			|| DATA_DIR="$EXECUTION_DIR/temp-db" \
			;
	}

	mkdir -p "$DATA_DIR"
	cd "$DATA_DIR"

	[ $DB_HOST ] || DB_HOST=127.0.0.1
	[ $DB_PORT ] || DB_PORT=5432
	[ $DB_NAME ] || DB_NAME=postgres
	[ $DB_USER ] || DB_USER=postgres

	PSQL_ARGS+=(-h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER)
}
