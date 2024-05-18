__CHECK_REQUIRED_ENV() {
	# checks all environment variables in REQUIRED_ENV=()
	local SCWRYPTS_LOG_LEVEL=4
	local VAR ERRORS=0

	REQUIRED_ENV=($(echo $REQUIRED_ENV | sed 's/\s\+/\n/g' | sort --unique))

	for VAR in ${REQUIRED_ENV[@]}; do __CHECK_ENV_VAR $VAR || ((ERRORS+=1)); done

	return $ERRORS
}

__CHECK_ENV_VAR() {
	local NAME OPTIONAL DEFAULT_VALUE LOOKUP_PATH
	local NAME_IS=environment-variable

	local USAGE="
		usage: __CHECK_ENV_VAR <environment variable> [...options...]

		options:
		  --optional   marks the variable as optional
		  --default    marks the variable as optional and provides a default value


		Verifies the existence of an environment variable in the current
		runtime. When running in scwrypts, allows lookup of environment variable
		values by either environment variable name or config lookup path:

		    __CHECK_ENV_VAR AWS_ACCOUNT
		    __CHECK_ENV_VAR .aws.account

		When in CI, environment _values_ must always come from the corresponding
		configuration env var (even when lookup is a config lookup path)
	"


	local _S ERRORS=0 POSITIONAL_ARGS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			-h | --help ) USAGE; return 0 ;;
			--optional ) OPTIONAL=true ;;
			--default )
				[ $2 ] && ((_S+=1)) \
					|| ERROR "missing env var default value" \
					|| break

				[ ! "$DEFAULT_VALUE" ] \
					|| ERROR "only one default value is supported" \
					|| break

				[[ $OPTIONAL =~ true ]] \
					&& WARNING "--optional and --default flags are redundant; remove '--optional' flag"

				DEFAULT_VALUE="$2"
				OPTIONAL=true
				;;
			* )
				((POSITIONAL_ARGS+=1))
				[[ $POSITIONAL_ARGS -le 2 ]] || ERROR "unknown argument '$1'"
				case $POSITIONAL_ARGS in
					1 ) NAME="$1" ;;
					2 ) DEFAULT_VALUE="$1"
						WARNING "use of positional argument for default value is DEPRECATED\nplease use --default <value> flag"
						;;
				esac
				;;
		esac
		shift $_S
	done

	[ "$NAME" ] \
		|| ERROR "must provide environment variable name"

	[ "$OPTIONAL" ] || OPTIONAL=false

	echo "$NAME" | grep -q '^\.' \
		&& NAME_IS=lookup-path

	case $NAME_IS in
		lookup-path )
			[ $__SCWRYPT ] || ERROR "lookup paths cannot be used outside of scwrypts ($NAME)"
			[ $__SCWRYPT ] && {
				use scwrypts/environment \
					|| ERROR "unable to load lookup path"

				LOOKUP_PATH="$NAME"
				NAME=$(\
					SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE \
						| YQ -r "$LOOKUP_PATH.\".ENVIRONMENT\"" \
						| grep -v ^null$\
					)

				[ $NAME ] || ERROR "no .ENVIRONMENT key is configured for '$LOOKUP_PATH'"
			}
			;;
		environment-variable )
			;;
	esac

	CHECK_ERRORS --no-fail --no-usage || return $?

	##########################################

	[ $__SCWRYPT ] || local CI=true  # outside of scwrypts, environment must load like CI runtime
	[ $CI ] && {
		[ "$(eval echo '$'$NAME)" ] && return 0

		case $OPTIONAL in
			true )
				[ "$DEFAULT_VALUE" ] \
					&& export $NAME=$DEFAULT_VALUE \
					|| WARNING "environment variable '$NAME' is not set" \
					;

				return 0
				;;
			false )
				local ERROR_MESSAGE="missing required environment variable '$NAME'"
				[ "$LOOKUP_PATH" ] && ERROR_MESSAGE+=" (config path '$LOOKUP_PATH')"

				ERROR "$ERROR_MESSAGE"
				return 1
				;;
		esac
	}

	[ ! $LOOKUP_PATH ] && {
		LOOKUP_PATH="$(SCWRYPTS_ENVIRONMENT__GET_ENVVAR_LOOKUP_MAP | YQ -r ".$NAME")"
	}

	# ensure environment safety; prevent bleed in from user's runtime
	unset $NAME
	local VALUE
	for GET_VALUE_METHOD in \
		runtimeoverride \
		value \
		selection \
		;
	do
		VALUE=$(__CHECK_ENV_VAR__$GET_VALUE_METHOD "$NAME" "$LOOKUP_PATH")
		[ "$VALUE" ] && eval "export $NAME=$VALUE" && break
	done

	[ "$VALUE" ] && return 0


	case $OPTIONAL in
		true )
			[ "$DEFAULT_VALUE" ] \
				&& export $NAME=$DEFAULT_VALUE \
				|| WARNING "environment variable '$NAME' is not set" \
				;

			return 0
			;;
		false )
			local ERROR_MESSAGE="missing required environment variable '$NAME'"
			[ "$LOOKUP_PATH" ] && ERROR_MESSAGE+=" (config path '$LOOKUP_PATH')"

			ERROR "$ERROR_MESSAGE"
			return 1
			;;
	esac
}

__CHECK_ENV_VAR__runtimeoverride() {
	local NAME="$1"
	local LOOKUP_PATH="$2"
	eval echo '$'$NAME'__override'
}

__CHECK_ENV_VAR__value() {
	local NAME="$1"
	local LOOKUP_PATH="$2"
	SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_SHELL_VALUES \
		| YQ -r "$LOOKUP_PATH" \
		| grep -v '^null$' \
		;
}

__CHECK_ENV_VAR__selection() {
	local NAME="$1"
	local LOOKUP_PATH="$2"

	local SELECTION_VALUES=($(
		SCWRYPTS_ENVIRONMENT__GET_USER_ENVIRONMENT_SHELL_VALUES \
			| YQ -r ".$LOOKUP_PATH[]" \
			| grep -v '^null$' \
			))

	[[ ${#SELECTION_VALUES[@]} -gt 0 ]] || return

	echo "$SELECTION_VALUES" \
		| sed 's/\s\+/\n/g' \
		| FZF "select a value for '$NAME'" \
		;
}
