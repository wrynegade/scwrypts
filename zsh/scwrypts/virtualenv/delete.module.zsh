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
					* ) echo.error "unknown argument '$1'" ;;
				esac
		esac
		shift $_S
	done

	[ "$GROUP" ] || echo.error 'missing group argument'
	[ "$TYPE"  ] || echo.error 'missing type argument'

	utils.check-errors --no-fail || return $?

	##########################################

	_SCWRYPTS_VIRTUALENV__VALIDATE_ENVIRONMENT_CONTROLLER "$GROUP" "$TYPE" || {
		echo.status "no environment controller exists for $GROUP/$TYPE"
		return 0
	}

	local VIRTUALENV_PATH="$(_SCWRYPTS_VIRTUALENV__GET_PATH "$GROUP" "$TYPE")"
	[ -d "$VIRTUALENV_PATH" ] || {
		echo.success "no $GROUP/$TYPE environment detected"
		return 0
	}

	##########################################

	rm -rf -- "$VIRTUALENV_PATH" \
		&& echo.success "succesfully cleaned up $GROUP/$TYPE virtualenv" \
		|| echo.error "unabled to remove '$VIRTUALENV_PATH'" \
		;
}
