PRINT() {
	local MESSAGE
	local LAST_LINE_END='\n'
	local STDERR=1
	local STDOUT=0

	local LTRIM=1
	while [[ $# -gt 0 ]]
	do
		case $1 in
			-n | --no-trim-tabs ) LTRIM=0 ;;
			-x | --no-line-end  ) LAST_LINE_END='' ;;
			-o | --use-stdout   ) STDOUT=1; STDERR=0 ;;
			* ) MESSAGE+="$(echo $1) " ;;
		esac
		shift 1
	done

	MESSAGE="$(echo "$MESSAGE" | sed 's/%/%%/g')"

	local STYLED_MESSAGE="$({
		printf "${COLOR}"
		while IFS='' read line
		do
			[[ $PREFIX =~ ^[[:space:]]\+$ ]] && printf '\n'

			printf "${PREFIX} : $(echo "$line" | sed 's/^	\+//; s/ \+$//')"

			PREFIX=$(echo $PREFIX | sed 's/./ /g')
		done <<< $MESSAGE
	})"
	STYLED_MESSAGE="${COLOR}$(echo "$STYLED_MESSAGE" | sed 's/%/%%/g')${__COLOR_RESET}${LAST_LINE_END}"

	[[ $STDERR -eq 1 ]] && printf $STYLED_MESSAGE >&2
	[[ $STDOUT -eq 1 ]] && printf $STYLED_MESSAGE

	return 0
}

[ ! $ERRORS ] && ERRORS=0
ERROR()    { PREFIX="ERROR    ✖" COLOR=$__RED    PRINT "$@"; ((ERRORS+=1)); }
SUCCESS()  { PREFIX="SUCCESS  ✔" COLOR=$__GREEN  PRINT "$@"; }
WARNING()  { PREFIX="WARNING  " COLOR=$__ORANGE PRINT "$@"; }
STATUS()   { PREFIX="STATUS    " COLOR=$__BLUE   PRINT "$@"; }
REMINDER() { PREFIX="REMINDER " COLOR=$__PURPLE PRINT "$@"; }
INFO()     { PREFIX="INFO     " COLOR=$__WHITE  PRINT "$@"; }

PROMPT() {
	PREFIX="PROMPT   " COLOR=$__CYAN PRINT "$@"
	PREFIX="USER     " COLOR=$__CYAN PRINT '' --no-line-end
}

FAIL()  { ERROR "${@:2}"; exit $1; }
ABORT() { FAIL 69 'user abort'; }

CHECK_ERRORS() {
	local FAIL_OUT=1
	local DISPLAY_USAGE=1

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--no-fail  ) FAIL_OUT=0 ;;
			--no-usage ) DISPLAY_USAGE=0 ;;
		esac
		shift 1
	done

	[ ! $ERRORS ] && ERRORS=0
	[[ $ERRORS -eq 0 ]] && return 0

	[[ $DISPLAY_USAGE -eq 1 ]] && USAGE

	[[ $FAIL_OUT -eq 1 ]] && exit $ERRORS

	return $ERRORS
}

USAGE() { # formatter for USAGE variable
	[ ! $USAGE ] && return 0
	local USAGE_LINE=$(echo $USAGE | grep -i '^[	]*usage *:' | sed 's/^[		]*//')

	[ $USAGE__usage ] && echo $USAGE_LINE | grep -q 'usage: -' \
		&& USAGE_LINE=$(echo $USAGE_LINE | sed "s/usage: -/usage: $USAGE__usage/")

	[ $__SCWRYPT ] \
		&& USAGE_LINE=$(
			echo $USAGE_LINE \
				| sed "s;^[^:]*:;& scwrypts $SCWRYPT_NAME --;" \
				| sed 's/ \{2,\}/ /g; s/scwrypts -- scwrypts/scwrypts/' \
			)

	local THE_REST=$(echo $USAGE | grep -vi '^[		]*usage *:' )

	local DYNAMIC_USAGE_ELEMENT
	#
	# create dynamic usage elements (like 'args') by defining USAGE__<element>
	# then using the syntax "<element>: -" in your USAGE variable
	#
	# e.g.
	#
	# USAGE__args="
	#	subcommand arg 1   arg 1 description
	#   subcommand arg 2   some other description
	# "
	#
	# USAGE="
	# usage: some-command [...args...]
	#
	# args: -
	#   -h, --help   some arguments are applicable everywhere
	# "
	#
	for DYNAMIC_USAGE_ELEMENT in $(echo $THE_REST | sed -n 's/^\([^:]*\): -$/\1/p')
	do
		DYNAMIC_USAGE_ELEMENT_TEXT=$(eval echo '$USAGE__'$DYNAMIC_USAGE_ELEMENT)

		[[ ! $DYNAMIC_USAGE_ELEMENT =~ ^description$ ]] \
			&& DYNAMIC_USAGE_ELEMENT_TEXT=$(echo $DYNAMIC_USAGE_ELEMENT_TEXT | sed 's/[^	]/  &/')

		THE_REST=$(echo $THE_REST | perl -pe "s/$DYNAMIC_USAGE_ELEMENT: -/$DYNAMIC_USAGE_ELEMENT:\n$DYNAMIC_USAGE_ELEMENT_TEXT\n\n/")
	done

	# allow for dynamic 'description: -' but delete the 'description:' header line
	THE_REST=$(echo $THE_REST | sed '/^[		]*description:$/d')

	echo "$__DARK_BLUE$USAGE_LINE$__COLOR_RESET\n\n$THE_REST" \
		| sed "s/^\t\+//; s/\s\+$//; s/^\\s*$//;" \
		| sed '/./,$!d; :a; /^\n*$/{$d;N;ba;};' \
		| perl -p0e 's/\n{2,}/\n\n/g' \
		| perl -p0e 's/:\n{2,}/:\n/g' \
		>&2
}

INPUT() {
	PROMPT "${@:2}"
	READ $1
	local VALUE=$(eval echo '$'$1)
	[ $VALUE ]
}

Yn() {
	PROMPT "$@ [Yn]"
	[ $CI ] && { echo y; return 0; }

	local Yn; READ -k Yn; echo >&2
	[[ $Yn =~ [nN] ]] && return 1 || return 0
}

yN() {
	PROMPT "$@ [yN]"
	[ $CI ] && { echo y; return 0; }

	local yN; READ -k yN; echo >&2
	[[ $yN =~ [yY] ]] && return 0 || return 1
}

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

#####################################################################

GETSUDO() {
	echo "\\033[1;36mPROMPT    : checking sudo password...\\033[0m" >&2
	sudo echo hi >/dev/null 2>&1 </dev/tty \
		&& SUCCESS '...authenticated!' \
		|| { ERROR 'failed :c'; return 1; }
}

LESS() { less -R $@ </dev/tty >/dev/tty; }

FZF()      {
	[ $CI ] && {
		ERROR 'currently in CI, but FZF requires user input'
		exit 1
	}

	local FZF_ARGS=()

	FZF_ARGS+=(-i)
	FZF_ARGS+=(--ansi)
	FZF_ARGS+=(--bind=ctrl-c:cancel)
	FZF_ARGS+=(--height=50%)
	FZF_ARGS+=(--layout=reverse)

	local SELECTION=$(fzf ${FZF_ARGS[@]} --layout=reverse --prompt "$1 : " ${@:2})
	PROMPT "$1"
	echo $SELECTION >&2
	echo $SELECTION
}
FZF_HEAD() { FZF $@ --print-query | sed '/^$/d' | head -n1; } # prefer user input over selected
FZF_TAIL() { FZF $@ --print-query | sed '/^$/d' | tail -n1; } # prefer selected over user input

READ()  {
	[ $CI ] && {
		INFO 'currently in CI, skipping READ'
		return 0
	}
	read $@ </dev/tty
}

EDIT() {
	[ $CI ] && {
		INFO 'currently in CI, skipping EDIT'
		return 0
	}

	STATUS "opening '$1' for editing"
	$EDITOR $@ </dev/tty >/dev/tty
	SUCCESS "finished editing '$1'!"
}
