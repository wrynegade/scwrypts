#####################################################################

DEPENDENCIES+=(
	virtualenv
	nodeenv
)
REQUIRED_ENV+=()

use utils

#####################################################################

AVAILABLE_VIRTUALENVS=(py zx)

REFRESH_VIRTUALENV() {
	local GROUP="$1"
	local TYPE="$2"
	[ ! $TYPE ] && {
		ERROR 'no virtualenv type specified'
		return 1
	}
	STATUS "refreshing $GROUP/$TYPE virtual environment"
	DELETE_VIRTUALENV $GROUP $TYPE \
		&& UPDATE_VIRTUALENV $GROUP $TYPE \
		&& SUCCESS 'successfully refreshed virtual environment' \
		|| { ERROR 'something went wrong during refresh (see above)'; return 1; } \
		;
}

UPDATE_VIRTUALENV() {
	local GROUP="$1"
	local TYPE="$2"
	[ ! $TYPE ] && {
		ERROR 'no virtualenv type specified'
		return 1
	}

	local VIRTUALENV_PATH=$(GET_VIRTUALENV_PATH $GROUP $TYPE)

	[ ! -d $VIRTUALENV_PATH ] && CREATE_VIRTUALENV__${GROUP}__${TYPE} $VIRTUALENV_PATH

	STATUS "updating $TYPE virtual environment"

	source $VIRTUALENV_PATH/bin/activate || {
		ERROR 'failed to activate virtualenv; did create fail?'
		return 1
	}

	cd $SCWRYPTS_ROOT
	local UPDATE_CODE=0
	case $TYPE in
		py ) cd py; pip install --no-cache-dir -r requirements.txt; UPDATE_CODE=$? ;;
		zx ) cd zx; npm install ;;
	esac
	UPDATE_CODE=$?
	[[ $UPDATE_CODE -eq 0 ]] \
		&& SUCCESS "$TYPE virtual environment up-to-date" \
		|| ERROR "failed to update $TYPE virtual environment (see errors above)" \
		;

	deactivate_node >/dev/null 2>&1
	deactivate >/dev/null 2>&1
	return $UPDATE_CODE
}

DELETE_VIRTUALENV() {
	local GROUP="$1"
	local TYPE="$2"
	local VIRTUALENV_PATH="$(GET_VIRTUALENV_PATH $GROUP $TYPE)"

	STATUS "dropping $TYPE virtual environment artifacts"

	[ ! -d $VIRTUALENV_PATH ] && {
		SUCCESS "no $TYPE environment detected"
		return 0
	}

	rm -rf $VIRTUALENV_PATH \
		&& SUCCESS "succesfully cleaned up $TYPE virtual environment" \
		|| { ERROR "unabled to remove '$VIRTUALENV_PATH'"; return 1; }
}

GET_VIRTUALENV_PATH() {
	local GROUP="$1"
	local TYPE="$2"

	local ENV_PATH="$(eval echo '$SCWRYPTS_VIRTUALENV_PATH__'$GROUP 2>/dev/null)"
	[ ! $ENV_PATH ] && ENV_PATH="$SCWRYPTS_VIRTUALENV_PATH__scwrypts"

	echo $ENV_PATH/$TYPE
}

#####################################################################

CREATE_VIRTUALENV__scwrypts__py() {
	local VIRTUALENV_PATH="$1"

	STATUS 'creating python virtual environment'
	local PY PYTHON
	for PY in $(echo $SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts)
	do
		which python$PY >/dev/null 2>&1 && {
			PYTHON=$(which python$PY)
			break
		}
	done
	[ ! $PYTHON ] && {
		ERROR 'python>=3.9 not available; skipping python env'
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

CREATE_VIRTUALENV__scwrypts__zx() {
	local VIRTUALENV_PATH="$1"

	STATUS 'setting up nodeenv'
	nodeenv $VIRTUALENV_PATH --node=$SCWRYPTS_NODE_VERSION__scwrypts \
		&& SUCCESS 'node virtualenv created' \
		|| {
			ERROR "unable to create '$VIRTUALENV_PATH' with '$SCWRYPTS__NODE_VERSION'"
			return 2
		}
}
