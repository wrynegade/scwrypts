#####################################################################

DEPENDENCIES+=(grep jq sed sort yq)

use utils

#####################################################################

SCWRYPTS_ENVIRONMENT__GET_ENV_NAMES() {
	[ $REQUIRED_ENVIRONMENT_REGEX ] && {
		_SCWRYPTS_ENVIRONMENT__FIND_ENV_NAMES | grep "$REQUIRED_ENVIRONMENT_REGEX"
		return $?
	}

	_SCWRYPTS_ENVIRONMENT__FIND_ENV_NAMES
}

SCWRYPTS_ENVIRONMENT__GET_ENV_FILE_NAME() {  # provides the fully qualified path to the group config file
	local NAME="$1"
	local GROUP="$2"
	[ $NAME ] && [ $GROUP ] \
		|| echo.error 'cannot determine environment filename without name ($1) and group ($2)' \
		|| return 1

	echo "$SCWRYPTS_ENV_PATH/$NAME.$GROUP.env.yaml"
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__GET_PARENT_ENV_NAMES() {  # deepest parent first; e.g. for 'a.b.c.d', returns (a a.b a.b.c)
	local NAME="$1"
	[[ $NAME =~ . ]] || return 0

	local PARENT_ENV_NAMES=()
	while [ $NAME ]
	do
		NAME="$(echo $NAME | sed -n 's/\.[^.]\+$//p')"
		[ $NAME ] && PARENT_ENV_NAMES+=($NAME)
	done

	echo ${PARENT_ENV_NAMES[@]} | sed 's/\s\+/\n/g' | sort
}

_SCWRYPTS_ENVIRONMENT__FIND_ENV_FILES() {
	find "$SCWRYPTS_ENV_PATH/" -mindepth 1 -maxdepth 1 -type f -name \*.env.yaml 2>/dev/null
}

_SCWRYPTS_ENVIRONMENT__FIND_ENV_NAMES() {
	_SCWRYPTS_ENVIRONMENT__FIND_ENV_FILES \
		| sed "s|^$SCWRYPTS_ENV_PATH/||; s|\\.[^.]\\+\\.env\\.yaml$||" \
		| sort --reverse --unique \
		;
}

_SCWRYPTS_ENVIRONMENT__FIND_ENV_FILES_BY_NAME() {
	local NAME="$1"
	[ $NAME ] || return 1

	find "$SCWRYPTS_ENV_PATH/" -mindepth 1 -maxdepth 1 -type f -name $NAME.\*.env.yaml 2>/dev/null
}

_SCWRYPTS_ENVIRONMENT__COMBINE_TEMPLATE_FILES() {
	utils.yq eval-all '. as $item ireduce ({}; . * $item)' \
		| sed 's/: {}$/:/' \
		| utils.yq 'sort_keys(...)' \
}
