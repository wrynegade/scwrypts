_DEPENDENCIES+=(
	virtualenv
	nodeenv
)
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

__AVAILABLE_VIRTUALENVS=(python node)

#####################################################################

__REFRESH_VIRTUALENV() {
	local TYPE="$1"
	[ ! $TYPE ] && {
		__ERROR 'no virtualenv type specified'
		return 1
	}
	__STATUS "refreshing $TYPE virtual environment"
	__DELETE_VIRTUALENV $TYPE \
		&& __UPDATE_VIRTUALENV $TYPE \
		&& __SUCCESS 'successfully refreshed virtual environment' \
		|| { ERROR 'something went wrong during refresh (see above)'; return 1; } \
		;
}

__UPDATE_VIRTUALENV() {
	local TYPE="$1"
	[ ! $TYPE ] && {
		__ERROR 'no virtualenv type specified'
		return 1
	}

	local VIRTUALENV_PATH=$(__GET_VIRTUALENV_PATH $TYPE)

	[ ! -d $VIRTUALENV_PATH ] && __CREATE_VIRTUALENV_$TYPE $VIRTUALENV_PATH

	__STATUS "updating $TYPE virtual environment"

	source $VIRTUALENV_PATH/bin/activate || {
		__ERROR 'failed to activate virtualenv; did create fail?'
		return 1
	}

	cd $SCWRYPTS_ROOT
	local UPDATE_CODE=0
	case $TYPE in
		python ) cd py; pip install -r requirements.txt; UPDATE_CODE=$? ;;
		node   ) cd zx; npm install ;;
	esac
	UPDATE_CODE=$?
	[[ $UPDATE_CODE -eq 0 ]] \
		&& __SUCCESS "$TYPE virtual environment up-to-date" \
		|| __ERROR "failed to update $TYPE virtual environment (see errors above)" \
		;

	deactivate_node >/dev/null 2>&1
	deactivate >/dev/null 2>&1
	return $UPDATE_CODE
}

__DELETE_VIRTUALENV() {
	local TYPE="$1"
	local VIRTUALENV_PATH="$(__GET_VIRTUALENV_PATH $TYPE)"

	__STATUS "dropping $TYPE virtual environment artifacts"

	[ ! -d $VIRTUALENV_PATH ] && {
		__SUCCESS "no $TYPE environment detected"
		return 0
	}

	rm -rf $VIRTUALENV_PATH \
		&& __SUCCESS "succesfully cleaned up $TYPE virtual environment" \
		|| { __ERROR "unabled to remove '$VIRTUALENV_PATH'"; return 1; }
}

__GET_VIRTUALENV_PATH() {
	local TYPE="$1"
	case $TYPE in
		python ) echo "$SCWRYPTS_VIRTUALENV_PATH/py" ;;
		node   ) echo "$SCWRYPTS_VIRTUALENV_PATH/zx" ;;
	esac
}

#####################################################################

__CREATE_VIRTUALENV_python() {
	local VIRTUALENV_PATH="$1"

	__STATUS 'creating python virtual environment'
	local PY PYTHON
	for PY in $(echo $__PREFERRED_PYTHON_VERSIONS)
	do
		which python$PY >/dev/null 2>&1 && {
			PYTHON=$(which python$PY)
			break
		}
	done
	[ ! $PYTHON ] && {
		__ERROR 'python>=3.9 not available; skipping python env'
		return 1
	}

	__STATUS 'setting up virtualenv'
	virtualenv $VIRTUALENV_PATH --python="$PYTHON" \
		&& __SUCCESS 'python virtualenv created' \
		|| {
			__ERROR "unable to create '$VIRTUALENV_PATH' with '$PYTHON'"
			return 2
		}
}

__CREATE_VIRTUALENV_node() {
	local VIRTUALENV_PATH="$1"

	__STATUS 'setting up nodeenv'
	nodeenv $VIRTUALENV_PATH --node=$__NODE_VERSION \
		&& __SUCCESS 'node virtualenv created' \
		|| {
			__ERROR "unable to create '$VIRTUALENV_PATH' with '$__NODE_VERSION'"
			return 2
		}
}
