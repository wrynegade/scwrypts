#####################################################################

use utils

#####################################################################

SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS=()

use scwrypts/virtualenv/env/py
use scwrypts/virtualenv/env/zx

#####################################################################

_SCWRYPTS_VIRTUALENV__GET_PATH() {
	local GROUP="$1"
	local TYPE="$2"

	local ENV_PATH="$(eval echo '$SCWRYPTS_VIRTUALENV_PATH__'$GROUP)"
	[ "$ENV_PATH" ] || ENV_PATH="$SCWRYPTS_VIRTUALENV_PATH__scwrypts"

	mkdir -p "$ENV_PATH/$TYPE" &>/dev/null

	echo "$ENV_PATH/$TYPE"
}


_SCWRYPTS_VIRTUALENV__VALIDATE_ENVIRONMENT_CONTROLLER() {
	local GROUP="$1"
	local TYPE="$2"

	: \
		&& which     CREATE_VIRTUALENV__${GROUP}__${TYPE} &>/dev/null \
		&& which   ACTIVATE_VIRTUALENV__${GROUP}__${TYPE} &>/dev/null \
		&& which     UPDATE_VIRTUALENV__${GROUP}__${TYPE} &>/dev/null \
		&& which DEACTIVATE_VIRTUALENV__${GROUP}__${TYPE} &>/dev/null \
		;
}
