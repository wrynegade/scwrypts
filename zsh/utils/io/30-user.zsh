#####################################################################


utils.io.input() {  # read a single line of user input
	echo.prompt "${@:2}"
	utils.io.read $1
	local VALUE=$(eval echo '$'$1)
	[ ${VALUE} ]
}

# yes/no prompts   && = yes (exit code 0)
#                  || = no  (exit code 1)
utils.Yn() { [[ ! $(utils.io.read-yn $@ '[Yn]') =~ [nN] ]]; }  # default 'yes'
utils.yN() { [[   $(utils.io.read-yn $@ '[yN]') =~ [yY] ]]; }  # default 'no'

utils.io.edit() {  # edit a file in user's preferred editor
	[ ${CI} ] && {
		echo.warning 'currently in CI, skipping EDIT'
		return 0
	}

	echo.status "opening '$1' for editing"
	${EDITOR} $@ </dev/tty >/dev/tty
	echo.success "finished editing '$1'!"
}

utils.io.getsudo() {  # ensure a user has sudo permissions
	echo.prompt 'checking sudo password' --stdout | head -n1 >&2
	sudo echo hi >/dev/null 2>&1 </dev/tty \
		&& echo.success '...authenticated!' \
		|| echo.error 'failed :c' \
		|| return 1
}


#####################################################################

utils.io.read()  {
	[ ${CI} ] && [ -t 0 ] \
		&& utils.fail 42 'currently in CI, but attempting interactive read; aborting'

	local FORCE_USER_INPUT=false
	local ARGS=()

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--force-user-input ) FORCE_USER_INPUT=true ;;
			-k )
				ARGS+=($1)
				;;
			* ) ARGS+=($1) ;;
		esac
		shift 1
	done

	while read -k -t 0; do :; done;  # flush user stdin

	case ${FORCE_USER_INPUT} in
		true  )
			read ${PREARGS[@]} ${ARGS[@]} $@ </dev/tty
			;;
		false )
			[ -t 0 ] || ARGS=(-u 0 ${ARGS[@]})
			read ${ARGS[@]} $@
			;;
	esac
}

utils.io.read-yn() {  # yes/no read is suprisingly tricky
	local FORCE_USER_INPUT=false
	local USERPROMPT=()
	local READ_ARGS=()

	[ "${SCWRYPTS_LOG_LEVEL}" ] || local SCWRYPTS_LOG_LEVEL=4

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--force-user-input )
				# overrides 'scwrypts -y' and stdin pipe but not CI
				FORCE_USER_INPUT=true
				READ_ARGS+=($1)
				;;
			* ) USERPROMPT+=($1) ;;
		esac
		shift 1
	done

	##########################################

	local SKIP_USER_INPUT=false

	[ ${CI} ] \
		&& SKIP_USER_INPUT=true

	[ ${__SCWRYPTS_YES} ] && [[ ${__SCWRYPTS_YES} -eq 1 ]] && [[ ${FORCE_USER_INPUT} =~ false ]] \
		&& SKIP_USER_INPUT=true

	##########################################

	local yn
	echo.prompt "${USERPROMPT[@]}"

	case ${SKIP_USER_INPUT} in
		true ) yn=y ;;
		false )
			utils.io.read ${READ_ARGS[@]} -s -k yn
			;;
	esac

	[[ ${SCWRYPTS_LOG_LEVEL} -ge 1 ]] && echo ${yn} >&2

	echo ${yn}
}
