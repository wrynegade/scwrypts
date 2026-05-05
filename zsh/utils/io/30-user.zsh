#####################################################################

utils.io.input() {  # read a single line of user input
	echo.prompt "${@:2}"
	utils.io.read $1
	local VALUE=$(eval echo '$'$1)
	[ ${VALUE} ]
}

# yes/no prompts   && = yes (exit code 0)
#                  || = no  (exit code 1)
user.Yn() { [[ ! $(utils.io.read-yn $@ '[Yn]') =~ [nN] ]]; }  # default 'yes'
user.yN() { [[   $(utils.io.read-yn $@ '[yN]') =~ [yY] ]]; }  # default 'no'

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
	sudo echo hi &>/dev/null </dev/tty \
		&& echo.success '...authenticated!' \
		|| echo.error 'failed :c' \
		|| return 1
}


#####################################################################

utils.io.read()  {
	local stdin_is_a_terminal \
		&& [[ -t 0 ]] \
		&& stdin_is_a_terminal=true \
		|| stdin_is_a_terminal=false \
		;

	[[ "$(normalize.boolean CI)" == true ]] && [[ "${stdin_is_a_terminal}" == true ]] && {
		echo.error 'currently in CI, but attempting interactive read; aborting'
		return 42
	}

	local force_user_input=false
	local ARGS=()

	while [[ "${#}" -gt 0 ]]
	do
		case "${1}" in
			( --force-user-input ) force_user_input=true ;;
			( * ) ARGS+=("${1}") ;;
		esac
		shift 1
	done

	while read -k -t 0; do :; done;  # flush user stdin

	case "${force_user_input}" in
		( true )
			read "${PREARGS[@]}" "${ARGS[@]}" "${@}" </dev/tty
			;;
		( false )
			[[ "${stdin_is_a_terminal}" == false ]] && ARGS=(-u 0 ${ARGS[@]})
			read "${ARGS[@]}" "${@}"
			;;
	esac
}

utils.io.read-yn() {  # yes/no read is suprisingly tricky
	local force_user_input=false
	local USERPROMPT=()
	local read_args=()

	[[ "${SCWRYPTS_LOG_LEVEL}" ]] || local SCWRYPTS_LOG_LEVEL=4

	while [[ "${#}" -gt 0 ]]
	do
		case "${1}" in
			( --force-user-input )
				# overrides 'scwrypts -y' and stdin pipe but not CI
				force_user_input=true
				read_args+=($1)
				;;
			* ) USERPROMPT+=($1) ;;
		esac
		shift 1
	done

	##########################################

	local skip_user_input=false
	case "$(normalize.boolean CI)" in
		( true )  # always skip input in CI
			skip_user_input=true
			;;

		( false )
			[[ "${force_user_input}" == false ]] && [[ "$(normalize.boolean __SCWRYPTS_YES)" == true ]] \
				&& skip_user_input=true
			;;
	esac

	##########################################

	local yn
	echo.prompt "${USERPROMPT[@]}"

	case "${skip_user_input}" in
		( true  ) yn=y ;;
		( false ) utils.io.read "${read_args[@]}" -s -k yn ;;
	esac

	echo.prompt --only-response --response "${yn}"

	echo "${yn}"
}
