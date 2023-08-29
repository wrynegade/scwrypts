#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use scwrypts/environment-files

#####################################################################

SCWRYPTS__GET_AVAILABLE_SCWRYPTS() {
	local TYPE_COLOR='\033[0;37m'
	local GROUP GROUP_PATH GROUP_COLOR LOOKUP_PIDS=()
	{
	echo 'NAME^TYPE^GROUP'
	for GROUP in ${SCWRYPTS_GROUPS}
	do
		GROUP_PATH=$(eval echo '$SCWRYPTS_ROOT__'$GROUP)
		GROUP_COLOR=$(eval echo '$SCWRYPTS_COLOR__'$GROUP)

		GROUP_TYPE=$(eval echo '$SCWRYPTS_TYPE__'$GROUP)
		[ $GROUP_TYPE ] && MINDEPTH=1 && GROUP_TYPE="$GROUP_TYPE\\/" || MINDEPTH=2

		command -v SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__$GROUP >/dev/null 2>&1 \
			&& LOOKUP=SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__$GROUP \
			|| LOOKUP=SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__scwrypts \
			;

		{
		$LOOKUP \
			| sed "s|\\([^/]*\\)/\(.*\)$|$(printf $__COLOR_RESET)\\2^$(printf $TYPE_COLOR)\\1^$(printf $GROUP_COLOR)$GROUP$(printf $__COLOR_RESET)|" \
		} &
		LOOKUP_PIDS+=($!)
	done
	for p in ${LOOKUP_PIDS[@]}; do wait $p; done
	} | column -t -s '^'
}

SCWRYPTS__SEPARATE_SCWRYPT_SELECTION() {
	set -- $(echo $@ | sed -e 's/\x1b\[[0-9;]*m//g')
	while [[ $# -gt 0 ]]
	do
		[ ! $NAME  ] && NAME=$1  && shift 1 && continue
		[ ! $TYPE  ] && TYPE=$1  && shift 1 && continue
		[ ! $GROUP ] && GROUP=$1 && shift 1 && continue
		shift 1
	done
}

SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__scwrypts() {
	# implementation should output lines of the following format:
	# "${SCWRYPT_TYPE}/${SCWRYPT_NAME}"
	cd "$GROUP_PATH"
	find . -mindepth $MINDEPTH -type f -executable \
		| grep -v '\.git' \
		| grep -v 'node_modules' \
		| sed "s/^\\.\\///; s/\\.[^.]*$//; s/^/$GROUP_TYPE/" \
		| grep -v '^plugins/' \
		;
}

SCWRYPTS__GET_RUNSTRING() {
	local GROUP_PATH=$(eval echo '$SCWRYPTS_ROOT__'$SCWRYPT_GROUP)
	local RUNSTRING

	[ $SCWRYPT_NAME ] && [ $SCWRYPT_TYPE ] && [ $SCWRYPT_GROUP ] || {
		ERROR 'missing required information to get runstring'
		return 1
	}

	[ $ENV_REQUIRED ] && [[ $ENV_REQUIRED -eq 1 ]] && [ ! $ENV_NAME ] && {
		ERROR 'missing required information to get runstring'
		return 1
	}

	[ ! $RUNSTRING ] && typeset -f SCWRYPTS__GET_RUNSTRING__${SCWRYPT_GROUP}__${SCWRYPT_TYPE} >/dev/null 2>&1 && {
		RUNSTRING=$(SCWRYPTS__GET_RUNSTRING__${SCWRYPT_GROUP}__${SCWRYPT_TYPE})
		[ ! $RUNSTRING ] && {
			ERROR "SCWRYPTS__GET_RUNSTRING__${SCWRYPT_GROUP}__${SCWRYPT_TYPE} error"
			return 2
		}
	}

	[ ! $RUNSTRING ] && typeset -f SCWRYPTS__GET_RUNSTRING__${SCWRYPT_TYPE} >/dev/null 2>&1 && {
		RUNSTRING=$(SCWRYPTS__GET_RUNSTRING__${SCWRYPT_TYPE})
		[ ! $RUNSTRING ] && {
			ERROR "SCWRYPTS__GET_RUNSTRING__${SCWRYPT_TYPE} error"
			return 3
		}
	}

	[ ! $RUNSTRING ] && {
		ERROR "type ${SCWRYPT_TYPE} (group ${SCWRYPT_GROUP}) has no supported runstring generator"
		return 4
	}

	RUNSTRING="SCWRYPTS_ENV=$ENV_NAME; $RUNSTRING"
	RUNSTRING="source $SCWRYPTS_ROOT/zsh/lib/import.driver.zsh; $RUNSTRING"

	local _VIRTUALENV=$(eval echo '$SCWRYPTS_VIRTUALENV_PATH__'$SCWRYPT_GROUP'/$SCWRYPT_TYPE/bin/activate')
	[ -f $_VIRTUALENV ] && RUNSTRING="source $_VIRTUALENV; $RUNSTRING"

	local G SCWRYPTSENV
	for G in ${SCWRYPTS__GROUPS[@]}
	do
		SCWRYPTSENV="$SCWRYPTS_ENV_PATH/$G/$ENV_NAME"
		[ -f $SCWRYPTSENV ] && RUNSTRING="source $SCWRYPTSENV; $RUNSTRING"
	done

	echo "$RUNSTRING"
}

SCWRYPTS__GET_RUNSTRING__zsh() {
	__CHECK_DEPENDENCY zsh || return 1

	[ $(eval echo '$SCWRYPTS_TYPE__'$SCWRYPT_GROUP) ] \
		&& echo "source $GROUP_PATH/$SCWRYPT_NAME" \
		|| echo "source $GROUP_PATH/$SCWRYPT_TYPE/$SCWRYPT_NAME" \
		;

	return 0
}

SCWRYPTS__GET_RUNSTRING__py() {
	__CHECK_DEPENDENCY python || return 1
	CURRENT_PYTHON_VERSION=$(python --version | sed 's/^[^0-9]*\(3\.[^.]*\).*$/\1/')
	echo $SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts | grep -q $CURRENT_PYTHON_VERSION || {
		WARNING "only tested on the following python versions: $(printf ', %s.x' ${SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts[@]} | sed 's/^, //')"
		WARNING 'compatibility may vary'
	}

	echo "cd $GROUP_PATH; python -m $(echo $SCWRYPT_TYPE/$SCWRYPT_NAME | sed 's/\//./g; s/\.py$//; s/\.\.//')"
}

SCWRYPTS__GET_RUNSTRING__zx() {
	__CHECK_DEPENDENCY zx || return 1

	echo "export FORCE_COLOR=3; cd $GROUP_PATH; ./$SCWRYPT_TYPE/$SCWRYPT_NAME.js"
}
