#####################################################################

DEPENDENCIES+=(grep jq sed sort yq)

#####################################################################

${scwryptsmodule}.get-env-names() {
	[ $REQUIRED_ENVIRONMENT_REGEX ] && {
		scwrypts.environment.common.find-env-names \
			| grep "$REQUIRED_ENVIRONMENT_REGEX"
		return $?
	}

	scwrypts.environment.common.find-env-names
}

${scwryptsmodule}.get-env-filename() {  # provides the fully qualified path to the group config file
	local NAME="$1"
	local GROUP="$2"
	[ $NAME ] && [ $GROUP ] \
		|| echo.error 'cannot determine environment filename without name ($1) and group ($2)' \
		|| return 1

	echo "$SCWRYPTS_ENV_PATH/$NAME.$GROUP.env.yaml"
}

${scwryptsmodule}.get-parent-env-names() {  # deepest parent first; e.g. for 'a.b.c.d', returns (a a.b a.b.c)
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

${scwryptsmodule}.find-env-files() {
	find "$SCWRYPTS_ENV_PATH/" -mindepth 1 -maxdepth 1 -type f -name \*.env.yaml 2>/dev/null
}

${scwryptsmodule}.find-env-names() {
	scwrypts.environment.common.find-env-files \
		| sed "s|^$SCWRYPTS_ENV_PATH/||; s|\\.[^.]\\+\\.env\\.yaml$||" \
		| sort --reverse --unique \
		;
}

${scwryptsmodule}.find-env-files-by-name() {
	local NAME="$1"
	[ $NAME ] || return 1

	find "$SCWRYPTS_ENV_PATH/" -mindepth 1 -maxdepth 1 -type f -name $NAME.\*.env.yaml 2>/dev/null
}

${scwryptsmodule}.combine-template-files() {
	utils.yq eval-all '. as $item ireduce ({}; . * $item)' \
		| sed 's/: {}$/:/' \
		| utils.yq 'sort_keys(...)' \
}
