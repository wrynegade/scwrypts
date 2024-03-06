#####################################################################
### basic colorized print messages ##################################
#####################################################################

source "${0:a:h}/io.print.zsh"
[ ! $ERRORS ] && ERRORS=0

ERROR() {  # command encountered an error
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] \
		&& PREFIX="ERROR    ✖" COLOR=$__RED            PRINT "$@"
	((ERRORS+=1))
	return $ERRORS
}

SUCCESS() {  # command completed successfully
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] \
		&& PREFIX="SUCCESS  ✔" COLOR=$__GREEN          PRINT "$@"
	return 0
}

REMINDER() {  # include sysadmin reminder or other important notice to users
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] \
		&& PREFIX="REMINDER " COLOR=$__BRIGHT_MAGENTA PRINT "$@"
	return 0
}

STATUS() {  # general status updates (prefer this to generic 'echo')
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 2 ]] \
		&& PREFIX="STATUS    " COLOR=$__BLUE           PRINT "$@"
	return 0
}

WARNING() {  # warning-level messages; not errors
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 3 ]] \
		&& PREFIX="WARNING  " COLOR=$__YELLOW         PRINT "$@"
	return 0
}

DEBUG() {  # helpful during development or (sparingly) to help others' development
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 4 ]] \
		&& PREFIX="DEBUG    ℹ" COLOR=$__WHITE          PRINT "$@"
	return 0
}

PROMPT() {  # you probably want to use yN or INPUT from below
	[ ! $SCWRYPTS_LOG_LEVEL ] && local SCWRYPTS_LOG_LEVEL=4
	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] \
		&& PREFIX="PROMPT   " COLOR=$__CYAN PRINT "$@" \
		&& PREFIX="USER     ⌨" COLOR=$__BRIGHT_CYAN PRINT '' --no-line-end \
		;
	return 0
}

FAIL()  { SCWRYPTS_LOG_LEVEL=1 ERROR "${@:2}"; exit $1; }
ABORT() { FAIL 69 'user abort'; }

#####################################################################
### check for reported errors and format USAGE contents #############
#####################################################################

CHECK_ERRORS() {
	local FAIL_OUT=true
	local DISPLAY_USAGE=true

	[ ! $ERRORS ] && ERRORS=0

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--fail    ) FAIL_OUT=true  ;;
			--no-fail ) FAIL_OUT=false ;;

			--usage    ) DISPLAY_USAGE=true  ;;
			--no-usage ) DISPLAY_USAGE=false ;;
		esac
		shift 1
	done

	[[ $ERRORS -eq 0 ]] && return 0

	[[ $DISPLAY_USAGE =~ true ]] && USAGE

	[[ $FAIL_OUT =~ true ]] && exit $ERRORS || return $ERRORS
}

source "${0:a:h}/io.usage.zsh"

#####################################################################
### facilitate user prompt and input ################################
#####################################################################

# yes/no prompts   && = yes (exit code 0)
#                  || = no  (exit code 1)
Yn() { [[ ! $(READ_YN $@ '[Yn]') =~ [nN] ]]; }  # default 'yes'
yN() { [[   $(READ_YN $@ '[yN]') =~ [yY] ]]; }  # default 'no'

INPUT() {  # read a single line of user input
	PROMPT "${@:2}"
	READ $1
	local VALUE=$(eval echo '$'$1)
	[ $VALUE ]
}

source "${0:a:h}/io.fzf.zsh"  # allow user to select from a list of inputs

EDIT() {  # edit a file in user's preferred editor
	[ $CI ] && {
		WARNING 'currently in CI, skipping EDIT'
		return 0
	}

	STATUS "opening '$1' for editing"
	$EDITOR $@ </dev/tty >/dev/tty
	SUCCESS "finished editing '$1'!"
}

#####################################################################
### basic commands with tricky states or default requirements #######
#####################################################################

LESS() { less -R $@ </dev/tty >/dev/tty; }

YQ() {
	yq --version | grep -q mikefarah || {
		yq $@
		return $?
	}

	yq eval '... comments=""' | yq $@
}

#####################################################################
### other i/o utilities #############################################
#####################################################################

CAPTURE() {
	[ ! $USAGE ] && USAGE="
		usage: stdout-varname stderr-varname [...cmd and args...]

		captures stdout and stderr on separate variables for a command
	"
	{
		IFS=$'\n' read -r -d '' $2;
		IFS=$'\n' read -r -d '' $1;
	} < <((printf '\0%s\0' "$(${@:3})" 1>&2) 2>&1)
}


GETSUDO() {
	echo "\\033[1;36mPROMPT    : checking sudo password...\\033[0m" >&2
	sudo echo hi >/dev/null 2>&1 </dev/tty \
		&& SUCCESS '...authenticated!' \
		|| { ERROR 'failed :c'; return 1; }
}

READ()  {
	[ $CI ] && [ -t 0 ] \
		&& FAIL 42 'currently in CI, but attempting interactive read; aborting'

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

	case $FORCE_USER_INPUT in
		true  )
			read ${PREARGS[@]} ${ARGS[@]} $@ </dev/tty
			;;
		false )
			[ -t 0 ] || ARGS=(-u 0 ${ARGS[@]})
			read ${ARGS[@]} $@
			;;
	esac
}

READ_YN() {  # yes/no read is suprisingly tricky
	local FORCE_USER_INPUT=false
	local USERPROMPT=()
	local READ_ARGS=()

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

	[ $CI ] \
		&& SKIP_USER_INPUT=true

	[ $__SCWRYPTS_YES ] && [[ $__SCWRYPTS_YES -eq 1 ]] && [[ $FORCE_USER_INPUT =~ false ]] \
		&& SKIP_USER_INPUT=true

	##########################################

	local yn
	PROMPT "${USERPROMPT[@]}"

	local PERFORM_FAKE_PROMPT=false
	case $SKIP_USER_INPUT in
		true ) yn=y ;;
		false )
			[[ $SCWRYPTS_LOG_LEVEL -lt 1 ]] && {
				[[ $FORCE_USER_INPUT =~ false ]] && [ ! -t 0 ] \
					|| PERFORM_FAKE_PROMPT=true
			}

			[[ $PERFORM_FAKE_PROMPT =~ true ]] \
				&& echo -n "${USERPROMPT[@]} : " >&2

			READ ${READ_ARGS[@]} -s -k yn

			[[ $PERFORM_FAKE_PROMPT =~ true ]] \
				&& echo $yn >&2
			;;
	esac

	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] && echo $yn >&2

	echo $yn
}
