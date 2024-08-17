#####################################################################

use scwrypts/environment/common

#####################################################################

SCWRYPTS_ENVIRONMENT__SELECT_ENV() {
	SCWRYPTS_ENVIRONMENT__GET_ENV_NAMES \
		| FZF 'select an environment'
}

SCWRYPTS_ENVIRONMENT__SELECT_OR_CREATE_ENV() {
	SCWRYPTS_ENVIRONMENT__GET_ENV_NAMES \
		| FZF_USER_INPUT 'select / create an environment'
}

