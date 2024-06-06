#####################################################################
SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS+=(zx)
#####################################################################


CREATE_VIRTUALENV__scwrypts__zx() {
	[ $CI ] && return 0
	DEPENDENCIES=(nodeenv) CHECK_ENVIRONMENT || return 1
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "$VIRTUALENV_PATH" ] || return 1

	[ $CI ] && return 0
	[ -f "$VIRTUALENV_PATH/bin/activate" ] && return 0


	STATUS 'setting up nodeenv'
	nodeenv "$VIRTUALENV_PATH" --node=$SCWRYPTS_NODE_VERSION__scwrypts \
		&& SUCCESS 'node virtualenv created' \
		|| ERROR "unable to create '$VIRTUALENV_PATH' with '$SCWRYPTS_NODE_VERSION__scwrypts'" \
		;
}


ACTIVATE_VIRTUALENV__scwrypts__zx() {
	[ $CI ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "$VIRTUALENV_PATH" ] || return 1

	source "$VIRTUALENV_PATH/bin/activate" || {
		ERROR "failed to activate virtualenv $GROUP/$TYPE; did create fail?"
		return 1
	}
}


UPDATE_VIRTUALENV__scwrypts__zx() {
	[ $CI ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "$VIRTUALENV_PATH" ] || return 1

	(
		cd "$SCWRYPTS_ROOT__scwrypts/zx"
		npm install \
			;
		)
}


DEACTIVATE_VIRTUALENV__scwrypts__zx() {
	[ $CI ] && return 0
	##########################################

	local VIRTUALENV_PATH="$1"
	[ "$VIRTUALENV_PATH" ] || return 1

	deactivate_node >/dev/null 2>&1
	return 0
}
