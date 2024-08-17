#####################################################################

MOCKED_ENV=()

${scwryptsmodule}() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		(beta) mocks an environment variable for testing
	"

	local \
		ENVIRONMENT_VARIABLE_NAME ENVIRONMENT_VARIABLE_VALUE \
		PARSERS=()

	eval "$ZSHPARSEARGS"

	##########################################
	
	MOCKED_ENV+=(${ENVIRONMENT_VARIABLE_NAME})

	export ${ENVIRONMENT_VARIABLE_NAME}__original_value="${(P)ENVIRONMENT_VARIABLE_NAME}"
	export ${ENVIRONMENT_VARIABLE_NAME}=${ENVIRONMENT_VARIABLE_VALUE}
}

${scwryptsmodule}.restore() {
	local ENVIRONMENT_VARIABLE_NAME ORIGINAL_VALUE
	for ENVIRONMENT_VARIABLE_NAME in ${MOCKED_ENV[@]}
	do
		ORIGINAL_VALUE="$(eval echo '$'$ENVIRONMENT_VARIABLE_NAME'__original_value')"
		[ "$ORIGINAL_VALUE" ] \
			&& export ${ENVIRONMENT_VARIABLE_NAME}="$ORIGINAL_VALUE" \
			|| unset ${ENVIRONMENT_VARIABLE_NAME} \
			;

		unset ${ENVIRONMENT_VARIABLE_NAME}__checked 2>/dev/null
	done
	MOCKED_ENV=()
}

#####################################################################

${scwryptsmodule}.parse() {
	# local ENVIRONMENT_VARIABLE_NAME ENVIRONMENT_VARIABLE_VALUE
	local PARSED=0

	case $1 in
		--value )
			PARSED=2
			ENVIRONMENT_VARIABLE_VALUE="$2"
			;;

		* ) [[ $POSITIONAL_ARGS -gt 0 ]] && return 0
			((POSITIONAL_ARGS+=1))
			PARSED=1
			case $POSITIONAL_ARGS in
				1 ) ENVIRONMENT_VARIABLE_NAME="$1" ;;
			esac
			;;
	esac

	return $PARSED
}

${scwryptsmodule}.parse.usage() {
	USAGE__usage+=' function [...options...]'

	USAGE__args+='
		name   the name of the environment variable
	'

	USAGE__options+='
		--value   the value of the environment variable
	'
}

${scwryptsmodule}.parse.validate() {
	[ "$ENVIRONMENT_VARIABLE_NAME" ] \
		|| ERROR "no environment variable specified"

	echo "$MOCKED_ENV" | sed 's/\s\+/\n/g' | grep -q "^$ENVIRONMENT_VARIABLE_NAME$" \
		&& ERROR "environment variable '$ENVIRONMENT_VARIABLE_NAME' has already been mocked"
}
