#####################################################################

use utils

#####################################################################

SCWRYPTS__GET_AVAILABLE_SCWRYPTS() {
	local TYPE_COLOR='\033[0;37m'
	local GROUP GROUP_ROOT GROUP_COLOR LOOKUP_PIDS=()
	{
	echo 'NAME^TYPE^GROUP'
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		GROUP_ROOT="$(scwrypts.config.group ${GROUP} root)"
		GROUP_COLOR=$(scwrypts.config.group ${GROUP} color)
		[ "${GROUP_COLOR}" ] || GROUP_COLOR='\033[0m'

		GROUP_TYPE=$(scwrypts.config.group ${GROUP} type)
		[ ${GROUP_TYPE} ] && MINDEPTH=1 && GROUP_TYPE="${GROUP_TYPE}\\/" || MINDEPTH=2

		command -v SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__${GROUP} >/dev/null 2>&1 \
			&& LOOKUP=SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__${GROUP} \
			|| LOOKUP=SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__scwrypts \
			;

		{
		${LOOKUP} \
			| sed "s|\\([^/]*\\)/\(.*\)$|$(utils.colors.reset)\\2^$(printf ${TYPE_COLOR})\\1^$(printf ${GROUP_COLOR})${GROUP}$(utils.colors.reset)|" \
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
		[ ! ${NAME}  ] && NAME=$1  && shift 1 && continue
		[ ! ${TYPE}  ] && TYPE=$1  && shift 1 && continue
		[ ! ${GROUP} ] && GROUP=$1 && shift 1 && continue
		shift 1
	done
}

SCWRYPTS__LIST_AVAILABLE_SCWRYPTS__scwrypts() {
	# implementation should output lines of the following format:
	# "${SCWRYPT_TYPE}/${SCWRYPT_NAME}"
	cd "${GROUP_ROOT}"
	find . -mindepth ${MINDEPTH} -type f -executable \
		| grep -v '\.git' \
		| grep -v 'node_modules' \
		| sed "s/^\\.\\///; s/\\.[^.]*$//; s/^/${GROUP_TYPE}/" \
		| grep -v '^plugins/' \
		;
}

SCWRYPTS__GET_RUNSTRING() {
	local GROUP_ROOT=$(scwrypts.config.group ${SCWRYPT_GROUP} root)
	local RUNSTRING

	echo.debug "$SCWRYPT_NAME : $SCWRYPT_TYPE : $SCWRYPT_GROUP"
	[ ${SCWRYPT_NAME} ] && [ ${SCWRYPT_TYPE} ] && [ ${SCWRYPT_GROUP} ] || {
		echo.error 'missing required information to get runstring'
		return 1
	}

	[ ${ENV_REQUIRED} ] && [[ ${ENV_REQUIRED} -eq 1 ]] && [ ! ${ENV_NAME} ] && {
		echo.error 'missing required information to get runstring'
		return 1
	}

	[ ! ${RUNSTRING} ] && typeset -f SCWRYPTS__GET_RUNSTRING__${SCWRYPT_GROUP}__${SCWRYPT_TYPE} >/dev/null 2>&1 && {
		RUNSTRING=$(SCWRYPTS__GET_RUNSTRING__${SCWRYPT_GROUP}__${SCWRYPT_TYPE})
		[ ! ${RUNSTRING} ] && {
			echo.error "SCWRYPTS__GET_RUNSTRING__${SCWRYPT_GROUP}__${SCWRYPT_TYPE} error"
			return 2
		}
	}

	[ ! ${RUNSTRING} ] && typeset -f SCWRYPTS__GET_RUNSTRING__${SCWRYPT_TYPE} >/dev/null 2>&1 && {
		RUNSTRING=$(SCWRYPTS__GET_RUNSTRING__${SCWRYPT_TYPE})
		[ ! ${RUNSTRING} ] && {
			echo.error "SCWRYPTS__GET_RUNSTRING__${SCWRYPT_TYPE} error"
			return 3
		}
	}

	[ ! ${RUNSTRING} ] && {
		echo.error "type ${SCWRYPT_TYPE} (group ${SCWRYPT_GROUP}) has no supported runstring generator"
		return 4
	}

	RUNSTRING="SCWRYPTS_ENV=${ENV_NAME}; ${RUNSTRING}"
	RUNSTRING="source $(scwrypts.config.group scwrypts root)/zsh/import.driver.zsh; ${RUNSTRING}"

	local _VIRTUALENV="$(scwrypts.config.group ${SCWRYPT_GROUP} root)/$SCWRYPT_TYPE/bin/activate"
	[ -f ${_VIRTUALENV} ] && RUNSTRING="source ${_VIRTUALENV}; ${RUNSTRING}"

	local G SCWRYPTSENV
	for G in ${SCWRYPTS__GROUPS[@]}
	do
		SCWRYPTSENV="${SCWRYPTS_ENV_PATH}/${G}/${ENV_NAME}"
		[ -f ${SCWRYPTSENV} ] && RUNSTRING="source ${SCWRYPTSENV}; ${RUNSTRING}"
	done

	echo "${RUNSTRING}"
}

SCWRYPTS__GET_RUNSTRING__zsh() {
	utils.dependencies.check zsh || return 1

	local SCWRYPT_FILENAME

	[ $(scwrypts.config.group ${SCWRYPT_GROUP} type) ] \
		&& SCWRYPT_FILENAME="${GROUP_ROOT}/${SCWRYPT_NAME}" \
		|| SCWRYPT_FILENAME="${GROUP_ROOT}/${SCWRYPT_TYPE}/${SCWRYPT_NAME}" \
		;

	SCWRYPTS__GET_RUNSTRING__zsh__generic "${SCWRYPT_FILENAME}"
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
	[ ${ZSH_FILENAME} ] || {
		echo.error '
			to use SCWRYPTS__GET_RUNSTRING__zsh__generic, you must provide a
			ZSH_FILENAME (arg $1) where the MAIN function is defined
			'
		return 1
	}
	printf "
		source '${SCWRYPT_FILENAME}'
		utils.check-environment
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
					-h | --help    ) utils.io.usage; exit 0 ;;
					* ) MAIN_ARGS+=(\$1) ;;
				esac
				shift 1
			done
			MAIN \${MAIN_ARGS[@]}
		} "
}

SCWRYPTS__GET_RUNSTRING__py() {
	utils.dependencies.check python || return 1
	CURRENT_PYTHON_VERSION=$(python --version | sed 's/^[^0-9]*\(3\.[^.]*\).*$/\1/')
	echo ${SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts} | grep -q ${CURRENT_PYTHON_VERSION} || {
		echo.warning "only tested on the following python versions: $(printf ', %s.x' ${SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts[@]} | sed 's/^, //')"
		echo.warning 'compatibility may vary'
	}

	echo "cd ${GROUP_ROOT}; python -m $(echo ${SCWRYPT_TYPE}/${SCWRYPT_NAME} | sed 's/\//./g; s/\.py$//; s/\.\.//')"
}

SCWRYPTS__GET_RUNSTRING__zx() {
	utils.dependencies.check zx || return 1

	echo "export FORCE_COLOR=3; cd ${GROUP_ROOT}; ./${SCWRYPT_TYPE}/${SCWRYPT_NAME}.js"
}
