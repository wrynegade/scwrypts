#####################################################################
SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS+=(zx)
#####################################################################


CREATE_VIRTUALENV__scwrypts__zx() {
	[ ${CI} ] && return 0
	DEPENDENCIES=(nodeenv) CHECK_ENVIRONMENT || return 1
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	[ ${CI} ] && return 0
	[ -f "${VIRTUALENV_PATH}/bin/activate" ] && return 0


	echo.status 'setting up nodeenv'
	local NODEJS_VERSION=$(scwrypts.config nodejs.version)
	nodeenv "${VIRTUALENV_PATH}" --node=${NODEJS_VERSION} \
		&& echo.success 'node virtualenv created' \
		|| echo.error "unable to create '${VIRTUALENV_PATH}' with '${NODEJS_VERSION}'" \
		;
}


ACTIVATE_VIRTUALENV__scwrypts__zx() {
	[ ${CI} ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	source "${VIRTUALENV_PATH}/bin/activate" || {
		echo.error "failed to activate virtualenv ${GROUP}/${TYPE}; did create fail?"
		return 1
	}
}


UPDATE_VIRTUALENV__scwrypts__zx() {
	[ ${CI} ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	(
		cd "$(scwrypts.config.group scwrypts root)/zx"
		npm install \
			;
		)
}


DEACTIVATE_VIRTUALENV__scwrypts__zx() {
	[ ${CI} ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	deactivate_node >/dev/null 2>&1
	return 0
}
