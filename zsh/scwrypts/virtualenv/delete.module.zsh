#####################################################################

use scwrypts/virtualenv/common

#####################################################################

${scwryptsmodule}() {
	local TYPE

	local _S ERRORS=0 POSITIONAL_ARGS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			( * )
				((POSITIONAL_ARGS+=1))
				case ${POSITIONAL_ARGS} in
					( 1 ) TYPE="$1" ;;
					( * ) echo.error "unknown argument '$1'" ;;
				esac
		esac
		shift ${_S}
	done

	[ "${GROUP}" ] || echo.error 'missing group argument'
	[ "${TYPE}"  ] || echo.error 'missing type argument'

	utils.check-errors || return $?

	##########################################

	scwrypts.virtualenv.common.validate-controller "${TYPE}" || {
		echo.status "no environment controller exists for ${TYPE}"
		return 0
	}

	local VIRTUALENV_PATH="$(scwrypts.virtualenv.common.get-path "${TYPE}")"
	[ -d "${VIRTUALENV_PATH}" ] || {
		echo.success "no ${TYPE} environment detected"
		return 0
	}

	##########################################

	rm -rf -- "${VIRTUALENV_PATH}" \
		&& echo.success "succesfully cleaned up ${TYPE} virtualenv" \
		|| echo.error "unabled to remove '${VIRTUALENV_PATH}'" \
		;
}
