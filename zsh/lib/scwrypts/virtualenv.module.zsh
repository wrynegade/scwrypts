#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use utils

#####################################################################

AVAILABLE_VIRTUALENVS=(py zx)

REFRESH_VIRTUALENV() {
	local GROUP="$1"
	local TYPE="$2"
	local VIRTUALENV_PATH="$(_VIRTUALENV__GET_PATH)"

	[ ! $TYPE ] && { ERROR 'no virtualenv type specified'; return 1; }

	STATUS "refreshing $GROUP/$TYPE virtualenv"
	DELETE_VIRTUALENV $GROUP $TYPE \
		&& UPDATE_VIRTUALENV $GROUP $TYPE \
		&& SUCCESS 'successfully refreshed virtualenv' \
		|| { ERROR 'something went wrong during refresh (see above)'; return 1; } \
		;
}

UPDATE_VIRTUALENV() {
	local GROUP="$1"
	local TYPE="$2"
	local VIRTUALENV_PATH="$(_VIRTUALENV__GET_PATH)"

	[ ! $TYPE ] && { ERROR 'no virtualenv type specified'; return 1; }

	: \
		&& which CREATE_VIRTUALENV__${GROUP}__${TYPE} >/dev/null 2>&1 \
		&& which ACTIVATE_VIRTUALENV__${GROUP}__${TYPE} >/dev/null 2>&1 \
		&& which UPDATE_VIRTUALENV__${GROUP}__${TYPE} >/dev/null 2>&1 \
		&& which DEACTIVATE_VIRTUALENV__${GROUP}__${TYPE} >/dev/null 2>&1 \
		|| { STATUS "no virtualenv available for $GROUP/$TYPE; skipping"; return 0; }

	STATUS "updating $GROUP/$TYPE virtualenv" \
		&& CREATE_VIRTUALENV__${GROUP}__${TYPE} \
		&& ACTIVATE_VIRTUALENV__${GROUP}__${TYPE} \
		&& UPDATE_VIRTUALENV__${GROUP}__${TYPE} \
		&& DEACTIVATE_VIRTUALENV__${GROUP}__${TYPE} \
		&& SUCCESS "$GROUP/$TYPE virtualenv up-to-date" \
		|| { ERROR "failed to update $GROUP/$TYPE virtualenv (see errors above)"; return 2; }
}

DELETE_VIRTUALENV() {
	[ $CI ] && return 0

	local GROUP="$1"
	local TYPE="$2"
	local VIRTUALENV_PATH="$(_VIRTUALENV__GET_PATH)"

	[ ! $TYPE ] && { ERROR 'no virtualenv type specified'; return 1; }

	STATUS "dropping $GROUP/$TYPE virtualenv artifacts"

	[ ! -d $VIRTUALENV_PATH ] && {
		SUCCESS "no $GROUP/$TYPE environment detected"
		return 0
	}

	rm -rf $VIRTUALENV_PATH \
		&& SUCCESS "succesfully cleaned up $GROUP/$TYPE virtualenv" \
		|| { ERROR "unabled to remove '$VIRTUALENV_PATH'"; return 1; }
}

#####################################################################

_VIRTUALENV__GET_PATH() {
	local ENV_PATH="$(eval echo '$SCWRYPTS_VIRTUALENV_PATH__'$GROUP 2>/dev/null)"
	[ ! $ENV_PATH ] && ENV_PATH="$SCWRYPTS_VIRTUALENV_PATH__scwrypts"

	mkdir -p "$ENV_PATH/$TYPE" &>/dev/null

	echo $ENV_PATH/$TYPE
}

#####################################################################

CREATE_VIRTUALENV__scwrypts__py() {
	[ $CI ] && return 0
	[ -d $VIRTUALENV_PATH ] && return 0

	DEPENDENCIES=(virtualenv) CHECK_ENVIRONMENT || return 1

	STATUS 'creating python virtualenv'
	local PY PYTHON
	for PY in $(echo $SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts)
	do
		which python$PY >/dev/null 2>&1 && {
			PYTHON=$(which python$PY)
			break
		}
	done
	[ ! $PYTHON ] && {
		ERROR 'python>=3.10 not available; skipping python env'
		return 1
	}

	STATUS 'setting up virtualenv'
	virtualenv $VIRTUALENV_PATH --python="$PYTHON" \
		&& SUCCESS 'python virtualenv created' \
		|| {
			ERROR "unable to create '$VIRTUALENV_PATH' with '$PYTHON'"
			return 2
		}
}

ACTIVATE_VIRTUALENV__scwrypts__py() {
	[ $CI ] && return 0
	source $VIRTUALENV_PATH/bin/activate || {
		ERROR "failed to activate virtualenv $GROUP/$TYPE; did create fail?"
		return 1
	}
}

UPDATE_VIRTUALENV__scwrypts__py() {
	local PIP_INSTALL_ARGS=()

	PIP_INSTALL_ARGS+=(--no-cache-dir)
	PIP_INSTALL_ARGS+=(-r requirements.txt)

	cd "$SCWRYPTS_ROOT/py"
	pip install ${PIP_INSTALL_ARGS[@]}
}

DEACTIVATE_VIRTUALENV__scwrypts__py() {
	deactivate >/dev/null 2>&1
	return 0
}

##########################################

CREATE_VIRTUALENV__scwrypts__zx() {
	[ $CI ] && return 0
	[ -d $VIRTUALENV_PATH ] && return 0

	DEPENDENCIES=(nodeenv) CHECK_ENVIRONMENT || return 1

	STATUS 'setting up nodeenv'
	nodeenv $VIRTUALENV_PATH --node=$SCWRYPTS_NODE_VERSION__scwrypts \
		&& SUCCESS 'node virtualenv created' \
		|| {
			ERROR "unable to create '$VIRTUALENV_PATH' with '$SCWRYPTS_NODE_VERSION__scwrypts'"
			return 2
		}
}

ACTIVATE_VIRTUALENV__scwrypts__zx() {
	[ $CI ] && return 0
	source $VIRTUALENV_PATH/bin/activate || {
		ERROR "failed to activate virtualenv $GROUP/$TYPE; did create fail?"
		return 1
	}
}

UPDATE_VIRTUALENV__scwrypts__zx() {
	local NPM_INSTALL_ARGS=()

	cd "$SCWRYPTS_ROOT/zx"
	npm install ${NPM_INSTALL_ARGS[@]}
}

DEACTIVATE_VIRTUALENV__scwrypts__zx() {
	deactivate_node >/dev/null 2>&1
	return 0
}
