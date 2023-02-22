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

	local STYLED_MESSAGE="${COLOR}$({
		printf "${COLOR}"
		while IFS='' read line
		do
			[[ $PREFIX =~ ^[[:space:]]\+$ ]] && printf '\n'

			printf "${PREFIX} : $(echo "$line" | sed 's/^	\+//; s/ \+$//')"

			PREFIX=$(echo $PREFIX | sed 's/./ /g')
		done <<< $MESSAGE
	})${__COLOR_RESET}${LAST_LINE_END}"
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

	while [[ $# -gt 0 ]]
	do
		case $1 in
			-n | --no-fail ) FAIL_OUT=0 ;;
		esac
		shift 1
	done

	[ ! $ERRORS ] && ERRORS=0
	[[ $ERRORS -ne 0 ]] && USAGE
	[[ $ERRORS -eq 0 ]] || {
		[[ $FAIL_OUT -eq 1 ]] \
			&& exit $ERRORS \
			|| return $ERRORS
	}
}

USAGE() {
	[ ! $USAGE ] && return 0
	USAGE=$(echo $USAGE | sed "s/^\t\+//; s/\s\+$//")

	local USAGE_LINE=$(\
		echo $USAGE \
			| grep -i '^ *usage *:' \
			| sed "s;^[^:]*:;& scwrypts $SCWRYPT_NAME --;" \
			| sed 's/ \{2,\}/ /g; s/scwrypts -- scwrypts/scwrypts/' \
		)
	local THE_REST=$(echo $USAGE | grep -vi '^ *usage *:' | sed 'N;/^\n$/D;P;D;')

	{ echo; printf "$__DARK_BLUE $USAGE_LINE$__COLOR_RESET\n"; echo $THE_REST; echo } >&2
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

	local Yn; READ -k Yn; echo
	[[ $Yn =~ [nN] ]] && return 1 || return 0
}

yN() {
	PROMPT "$@ [yN]"
	[ $CI ] && { echo y; return 0; }

	local yN; READ -k yN; echo
	[[ $yN =~ [yY] ]] && return 0 || return 1
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

	local SELECTION=$(fzf -i --height=30% --layout=reverse --prompt "$1 : " ${@:2})
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
