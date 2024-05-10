###########################################################

use scwrypts/environment/common

###########################################################

${scwryptsmodule}() {
	local SELECTOR=utils.fzf
	local MESSAGE='select an environment'

	[[ "$1" =~ --allow-create ]] && {
		SELECTOR=utils.fzf.user-input
		MESSAGE='select / create an environment'
	}

	scwrypts.environment.common.get-env-names \
		| ${SELECTOR} "${MESSAGE}"
}
