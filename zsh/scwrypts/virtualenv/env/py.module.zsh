#####################################################################
SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS+=(py)
#####################################################################

virtualenv.py.create() {
	utils.dependencies.check virtualenv || return 1

	##########################################

	local VIRTUALENV_PATH="$(scwrypts.virtualenv.common.get-path py)"
	local PYTHON="$(virtualenv.py.get-base-executable)"

	[ -f "${VIRTUALENV_PATH}/bin/activate" ] && return 0

	echo.status 'creating python virtualenv'

	[ "${PYTHON}" ] \
		|| echo.error 'python>=3.10 not available; skipping python env' \
		|| return 1

	echo.status 'setting up virtualenv'
	virtualenv "${VIRTUALENV_PATH}" --python="${PYTHON}" \
		&& echo.success 'python virtualenv created' \
		|| echo.error "unable to create '${VIRTUALENV_PATH}' with '${PYTHON}'" \
		;
}

virtualenv.py.activate() {
	source "$(scwrypts.virtualenv.common.get-path py)/bin/activate"
}

virtualenv.py.deactivate() {
	deactivate &>/dev/null
	return 0
}

virtualenv.py.update() {
	local ERRORS=0
	local GROUP REQUIREMENTS_FILENAME

	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		case "$(eval echo "\$SCWRYPTS_GROUP_CONFIGURATION__${GROUP}__type")" in
			( '' )
				REQUIREMENTS_FILENAME="$(scwrypts.config.group ${GROUP} root)/py/requirements.txt"
				;;
			( py )
				REQUIREMENTS_FILENAME="$(scwrypts.config.group ${GROUP} root)/requirements.txt"
				;;
			( * )
				continue
				;;
		esac

		[ "${REQUIREMENTS_FILENAME}" ] && [ -f "${REQUIREMENTS_FILENAME}" ] \
			|| echo.error "group ${GROUP} appears to be misconfigured" \
			|| continue

		( cd "$(dirname -- "${REQUIREMENTS_FILENAME}")" \
			&& pip install \
				--no-cache-dir \
				--requirement "${REQUIREMENTS_FILENAME}" \
			) \
			|| echo.error "something went wrong during pip install for ${GROUP}" \
			|| continue
	done

	return ${ERRORS}
}

#####################################################################

virtualenv.py.get-base-executable() {
	local PY PYTHON
	for PY in $(scwrypts.config python.versions)
	do
		python --version | grep -qi " ${PY}" \
			&& which python \
			&& break \
			;

		which python${PY} &>/dev/null \
			&& which python${PY} \
			&& break \
			;
	done
}
