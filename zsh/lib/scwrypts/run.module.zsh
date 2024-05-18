#####################################################################

use utils

#####################################################################

SCWRYPTS__GET_AVAILABLE_SCWRYPTS() {
	local TYPE_COLOR='\033[0;37m'
	local GROUP GROUP_PATH GROUP_COLOR LOOKUP_PIDS=()
	{
	echo 'NAME^TYPE^GROUP'
	for GROUP in ${SCWRYPTS_GROUPS[@]}
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
	RUNSTRING="source $SCWRYPTS_ROOT__scwrypts/zsh/lib/import.driver.zsh; $RUNSTRING"

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

	local SCWRYPT_FILENAME

	[ $(eval echo '$SCWRYPTS_TYPE__'$SCWRYPT_GROUP) ] \
		&& SCWRYPT_FILENAME="$GROUP_PATH/$SCWRYPT_NAME" \
		|| SCWRYPT_FILENAME="$GROUP_PATH/$SCWRYPT_TYPE/$SCWRYPT_NAME" \
		;

	SCWRYPTS__GET_RUNSTRING__zsh__generic "$SCWRYPT_FILENAME"
	return 0
}

SCWRYPTS__GET_RUNSTRING__zsh__generic() {
	# boilerplate to allow
	#    - multiflag splitting (e.g. -abc = -a -b -c)
	#    - help flag injection (e.g. -h | --help)
	#    - default USAGE definition (allows USAGE__options style usage definition)
	#    - required MAIN() function wrapping
	#
	# this is available automatically in SCWRYPTS_GROUP declaration contexts
	# (e.g. my-group.scwrypts.zsh)
	local ZSH_FILENAME="$1"
	[ $ZSH_FILENAME ] || {
		ERROR '
			to use SCWRYPTS__GET_RUNSTRING__zsh__generic, you must provide a
			ZSH_FILENAME (arg $1) where the MAIN function is defined
			'
		return 1
	}
	printf "
		source '$SCWRYPT_FILENAME'
		CHECK_ENVIRONMENT
		ERRORS=0

		export USAGE=\"
			usage: -

			args: -

			options: -
			  -h, --help      display this message and exit

			description: -
		\"

		[ ! \$USAGE__usage ] && export USAGE__usage='[...options...]'

		() {
			local MAIN_ARGS=()
			local VARSPLIT
			while [[ \$# -gt 0 ]]
			do
				case \$1 in
					-[a-z][a-z]* )
						VARSPLIT=\$(echo \"\$1 \" | sed 's/^\\\\(-.\\\\)\\\\(.*\\\\) /\\\\1 -\\\\2/')
						set -- throw-away \$(echo \" \$VARSPLIT \") \${@:2}
						;;
					-h | --help    ) USAGE; exit 0 ;;
					* ) MAIN_ARGS+=(\$1) ;;
				esac
				shift 1
			done
			MAIN \${MAIN_ARGS[@]}
		} "
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
