#####################################################################

use scwrypts/virtualenv/common

#####################################################################

DELETE_VIRTUALENV() {
	local GROUP TYPE

	local _S ERRORS=0 POSITIONAL_ARGS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			* )
				((POSITIONAL_ARGS+=1))
				case $POSITIONAL_ARGS in
					1 ) GROUP="$1" ;;
					2 ) TYPE="$1" ;;
					* ) ERROR "unknown argument '$1'" ;;
				esac
		esac
		shift $_S
	done

	[ "$GROUP" ] || ERROR 'missing group argument'
	[ "$TYPE"  ] || ERROR 'missing type argument'

	CHECK_ERRORS --no-fail || return $?

	##########################################

	_SCWRYPTS_VIRTUALENV__VALIDATE_ENVIRONMENT_CONTROLLER "$GROUP" "$TYPE" || {
		STATUS "no environment controller exists for $GROUP/$TYPE"
		return 0
	}

	local VIRTUALENV_PATH="$(_SCWRYPTS_VIRTUALENV__GET_PATH "$GROUP" "$TYPE")"
	[ -d "$VIRTUALENV_PATH" ] || {
		SUCCESS "no $GROUP/$TYPE environment detected"
		return 0
	}

	##########################################

	rm -rf -- "$VIRTUALENV_PATH" \
		&& SUCCESS "succesfully cleaned up $GROUP/$TYPE virtualenv" \
		|| ERROR "unabled to remove '$VIRTUALENV_PATH'" \
		;
}
