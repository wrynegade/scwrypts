${scwryptsmodule}() {
	local GROUP_ROOT=$(scwrypts.config.group ${SCWRYPT_GROUP} root)
	local RUNSTRING

	[ ${SCWRYPT_NAME} ] && [ ${SCWRYPT_TYPE} ] && [ ${SCWRYPT_GROUP} ] || {
		echo.error 'missing required information to get runstring'
		return 1
	}

	[ ${ENV_REQUIRED} ] && [[ ${ENV_REQUIRED} -eq 1 ]] && [ ! ${SCWRYPTS_ENV} ] && {
		echo.error 'missing required information to get runstring'
		return 1
	}

	local GET_RUNSTRING
	for GET_RUNSTRING in \
		SCWRYPTS_GROUP_CONFIGURATION__${SCWRYPT_GROUP}.${SCWRYPT_TYPE}.get-runstring \
		scwrypts.get-runstring.${SCWRYPT_TYPE} \
		'no valid runstring generator' \
		;
	do
		command -v ${GET_RUNSTRING} &>/dev/null && {
			RUNSTRING="$(${GET_RUNSTRING})"
			break
		}
	done

	[ ${RUNSTRING} ] \
		|| echo.error "get-runstring error (${GET_RUNSTRING})" \
		|| return 2 \
		;

	echo "$(scwrypts.runstring.get-prefix) ${RUNSTRING}"
}

scwrypts.runstring.get-prefix() {
	local VIRTUALENV="${GROUP_ROOT}/${SCWRYPT_TYPE}/bin/activate"
	[ -f "${VIRTUALENV}" ] && printf "source \"${VIRTUALENV}\"; "

	printf "source \"$(scwrypts.config.group scwrypts root)/zsh/import.driver.zsh\"; "
	printf "SCWRYPTS_ENV=${SCWRYPTS_ENV}; "
}

#####################################################################

${scwryptsmodule}.zsh() {
	utils.dependencies.check zsh || return 1

	local SCWRYPT_FILENAME

	[ $(scwrypts.config.group ${SCWRYPT_GROUP} type) ] \
		&& SCWRYPT_FILENAME="${GROUP_ROOT}/${SCWRYPT_NAME}" \
		|| SCWRYPT_FILENAME="${GROUP_ROOT}/${SCWRYPT_TYPE}/${SCWRYPT_NAME}" \
		;

	scwrypts.get-runstring.zsh.generic
}

${scwryptsmodule}.zsh.generic() {
	#
	# boilerplate to allow
	#    - multiflag splitting (e.g. -abc = -a -b -c)
	#    - help flag injection (e.g. -h | --help)
	#    - default USAGE definition (allows USAGE__options style usage definition)
	#    - required MAIN() function wrapping
	#
	# this is available automatically in SCWRYPT_GROUP declaration contexts
	# (e.g. my-group.scwrypts.zsh)
	#
	[ "${SCWRYPT_FILENAME}" ] || {
		echo.error "must define a SCWRYPT_FILENAME"
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

#####################################################################

${scwryptsmodule}.py() {
	utils.dependencies.check python || return 1
	use scwrypts/virtualenv

	local VIRTUALENV_PATH="$(scwrypts.virtualenv.common.get-path py)"
	[ -f "${VIRTUALENV_PATH}/bin/activate" ] \
		|| scwrypts.virtualenv.update py &>/dev/null

	printf "
		source \"${VIRTUALENV_PATH}/bin/activate\"
		cd -- \"${GROUP_ROOT}\"
		python -m $(echo ${SCWRYPT_TYPE}/${SCWRYPT_NAME} | sed 's/\//./g; s/\.py$//; s/\.\.//') "
}

#####################################################################

${scwryptsmodule}.zx() {
	utils.dependencies.check zx || return 1
	use scwrypts/virtualenv/update

	local ZX_ROOT
	[[ "$(eval echo "\$SCWRYPTS_GROUP_CONFIGURATION__${GROUP}__type")" =~ zx ]] \
		&& ZX_ROOT="${GROUP_ROOT}" \
		|| ZX_ROOT="${GROUP_ROOT}/zx" \
		;

	[ -d "${ZX_ROOT}/node_modules" ] \
		|| scwrypts.virtualenv.update zx >&2

	printf "
		export FORCE_COLOR=3
		${ZX_ROOT}/${SCWRYPT_NAME}.js "
}
