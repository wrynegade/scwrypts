#####################################################################

SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS=()

use scwrypts/virtualenv/env/py
use scwrypts/virtualenv/env/zx

use scwrypts/virtualenv/zshparse

#####################################################################

${scwryptsmodule}.get-path() {
	local TYPE ARGS=() PARSERS=(
		scwrypts.virtualenv.zshparse.type-arg
	)

	eval "$ZSHPARSEARGS"

	##########################################

	local ENV_PATH="${SCWRYPTS_STATE_PATH}/virtualenv/${SCWRYPTS_ENV}/${TYPE}"

	mkdir -p -- "${ENV_PATH}" &>/dev/null

	echo "${ENV_PATH}"
}

${scwryptsmodule}.validate-controller() {
	local TYPE="$1"
	command -v \
			virtualenv.${TYPE}.create \
			virtualenv.${TYPE}.activate \
			virtualenv.${TYPE}.deactivate \
			virtualenv.${TYPE}.update \
		&>/dev/null
}
