#####################################################################
SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS+=(py)
#####################################################################


CREATE_VIRTUALENV__scwrypts__py() {
	[ ${CI} ] && return 0
	utils.dependencies.check virtualenv || return 1
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	[ -f "${VIRTUALENV_PATH}/bin/activate" ] && return 0


	echo.status 'creating python virtualenv'
	local PY PYTHON
	for PY in $(scwrypts.config python.versions)
	do
		which python${PY} >/dev/null 2>&1 && {
			PYTHON=$(which python${PY})
			break
		}
	done

	[ "${PYTHON}" ] \
		|| echo.error 'python>=3.10 not available; skipping python env' \
		|| return 1

	echo.status 'setting up virtualenv'
	virtualenv "${VIRTUALENV_PATH}" --python="${PYTHON}" \
		&& echo.success 'python virtualenv created' \
		|| echo.error "unable to create '${VIRTUALENV_PATH}' with '${PYTHON}'" \
		;
}


ACTIVATE_VIRTUALENV__scwrypts__py() {
	[ ${CI} ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	source "${VIRTUALENV_PATH}/bin/activate" \
		|| echo.error "failed to activate virtualenv ${GROUP}/${TYPE}; did create fail?"
}


UPDATE_VIRTUALENV__scwrypts__py() {
	[ ${CI} ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	(
		cd "$(scwrypts.config.group scwrypts root)/py"
		pip install \
			--no-cache-dir \
			--requirement requirements.txt \
			;
		)
}


DEACTIVATE_VIRTUALENV__scwrypts__py() {
	[ ${CI} ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "${VIRTUALENV_PATH}" ] || return 1

	deactivate &>/dev/null
	return 0
}
