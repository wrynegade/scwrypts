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
		{
		cd "$GROUP_PATH"
		find . -mindepth 2 -type f -executable \
			| grep -v '\.git' \
			| grep -v 'node_modules' \
			| sed "s/^\\.\\///; s/\\.[^.]*$//" \
			| sed "s|\\([^/]*\\)/\(.*\)$|$(printf $__COLOR_RESET)\\2^$(printf $TYPE_COLOR)\\1^$(printf $GROUP_COLOR)$GROUP$(printf $__COLOR_RESET)|" \
			;
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

SCWRYPTS__GET_RUNSTRING() {
	# accepts a selected line from SCWRYPTS__GET_AVAILABLE_SCWRYPTS
	local NAME="$1"
	local TYPE="$2"
	local GROUP="$3"
	local GROUP_PATH=$(eval echo '$SCWRYPTS_ROOT__'$GROUP)
	local RUNSTRING

	[ $NAME ] && [ $TYPE ] && [ $GROUP ] || {
		ERROR 'missing required information to get runstring'
		return 1
	}
	[ $ENV_REQUIRED ] && [[ $ENV_REQUIRED -eq 1 ]] && [ ! $ENV_NAME ] && {
		ERROR 'missing required information to get runstring'
		return 1
	}

	typeset -f SCWRYPTS__GET_RUNSTRING__${GROUP}__${TYPE} >/dev/null 2>&1 && {
		RUNSTRING=$(SCWRYPTS__GET_RUNSTRING__${GROUP}__${TYPE})
		[ ! $RUNSTRING ] && {
			ERROR "SCWRYPTS__GET_RUNSTRING__${GROUP}__${TYPE} error"
			return 2
		}
	}

	typeset -f SCWRYPTS__GET_RUNSTRING__${TYPE} >/dev/null 2>&1 && {
		RUNSTRING=$(SCWRYPTS__GET_RUNSTRING__${TYPE})
		[ ! $RUNSTRING ] && {
			ERROR "SCWRYPTS__GET_RUNSTRING__${TYPE} error"
			return 3
		}
	}

	[ ! $RUNSTRING ] && {
		ERROR "type ${TYPE} (group ${GROUP}) has no supported runstring generator"
		return 4
	}

	RUNSTRING="SCWRYPTS_ENV=$ENV_NAME; $RUNSTRING"
	RUNSTRING="source $SCWRYPTS_ROOT/zsh/lib/import.driver.zsh; $RUNSTRING"

	local _VIRTUALENV=$(eval echo '$SCWRYPTS_VIRTUALENV_PATH__'$GROUP'/$TYPE/bin/activate')
	[ -f $_VIRTUALENV ] && RUNSTRING="source $_VIRTUALENV; $RUNSTRING"

	local G SCWRYPTSENV
	for G in ${SCWRYPTS__GROUPS[@]}
	do
		SCWRYPTSENV=$(eval echo '$SCWRYPTS_ENV_PATH__'$GROUP'/$ENV_NAME')
		[ -f $SCWRYPTSENV ] && RUNSTRING="source $SCWRYPTSENV; $RUNSTRING"
	done

	echo "$RUNSTRING"
}

SCWRYPTS__GET_RUNSTRING__zsh() {
	__CHECK_DEPENDENCY zsh || return 1

	echo "source $GROUP_PATH/$TYPE/$NAME"
}

SCWRYPTS__GET_RUNSTRING__py() {
	__CHECK_DEPENDENCY python || return 1
	CURRENT_PYTHON_VERSION=$(python --version | sed 's/^[^0-9]*\(3\.[^.]*\).*$/\1/')
	echo $SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts | grep -q $CURRENT_PYTHON_VERSION || {
		WARNING "only tested on the following python versions: $(printf ', %s.x' ${SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts[@]} | sed 's/^, //')"
		WARNING 'compatibility may vary'
	}

	echo "cd $GROUP_PATH; python -m $(echo $TYPE/$NAME | sed 's/\//./g; s/\.py$//; s/\.\.//')"
}

SCWRYPTS__GET_RUNSTRING__zx() {
	__CHECK_DEPENDENCY zx || return 1

	echo "export FORCE_COLOR=3; cd $GROUP_PATH; ./$TYPE/$NAME.js"
}
