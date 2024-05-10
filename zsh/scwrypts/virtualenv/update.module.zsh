#####################################################################

use scwrypts/virtualenv/common
use scwrypts/virtualenv/zshparse

#####################################################################

${scwryptsmodule}() {
	eval "$(usage.reset)"
	local USAGE__description='
		update virtualenv dependencies
	'
	local TYPE ARGS=() PARSERS=(
		scwrypts.virtualenv.zshparse.type-arg
	)
	eval "$ZSHPARSEARGS"

	##########################################

	scwrypts.virtualenv.common.validate-controller "${TYPE}" \
		|| echo.error "no environment controller exists for ${TYPE}" \
		|| return 1

	: \
		&& virtualenv.${TYPE}.create \
		&& virtualenv.${TYPE}.activate \
		&& virtualenv.${TYPE}.update \
		&& virtualenv.${TYPE}.deactivate \
		&& echo.success "virtualenv '${TYPE}' up-to-date" \
		|| echo.error "failed to update '${TYPE}' virtualenv (see errors above)" \
		;
}

#####################################################################
