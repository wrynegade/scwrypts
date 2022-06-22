__ERROR()    { echo "\\033[1;31mERROR    ✖ : $@\\033[0m" >&2; }
__SUCCESS()  { echo "\\033[1;32mSUCCESS  ✔ : $@\\033[0m" >&2; }
__WARNING()  { echo "\\033[1;33mWARNING   : $@\\033[0m" >&2; }
__STATUS()   { echo "\\033[1;34mSTATUS     : $@\\033[0m" >&2; }
__REMINDER() { echo "\\033[1;35mREMINDER  : $@\\033[0m" >&2; }

__PROMPT() {
	echo   "\\033[1;36mPROMPT    : $@\\033[0m" >&2
	printf "\\033[1;36mUSER      : \\033[0m" >&2
}

__Yn() {
	__PROMPT "$@ [Yn]"
	[ $CI ] && { echo y; return 0; }

	local Yn; __READ -k Yn; echo
	[[ $Yn =~ [nN] ]] && return 1 || return 0
}

__yN() {
	__PROMPT "$@ [yN]"
	[ $CI ] && { echo y; return 0; }

	local yN; __READ -k yN; echo
	[[ $yN =~ [yY] ]] && return 0 || return 1
}

__FAIL()  { __ERROR "${@:2}"; exit $1; }

__ABORT() { __FAIL 69 'user abort'; }

#####################################################################

__GETSUDO() {
	echo "\\033[1;36mPROMPT    : checking sudo password...\\033[0m" >&2
	sudo echo hi >/dev/null 2>&1 </dev/tty \
		&& __SUCCESS '...authenticated!' \
		|| { __ERROR 'failed :c'; return 1; }
}

__LESS() { less -R $@ </dev/tty >/dev/tty; }

__FZF()      {
	[ $CI ] && {
		__ERROR 'currently in CI, but __FZF requires user input'
		exit 1
	}

	fzf -i --height=30% --layout=reverse --prompt "$1 : " ${@:2}
}
__FZF_HEAD() { __FZF $@ --print-query | sed '/^$/d' | head -n1; } # prefer user input over selected
__FZF_TAIL() { __FZF $@ --print-query | sed '/^$/d' | tail -n1; } # prefer selected over user input

__READ()  {
	[ $CI ] && {
		__ERROR 'currently in CI, but __READ explicitly requires terminal input'
		return 1
	}
	read $@ </dev/tty
}

__EDIT() {
	[ $CI ] && {
		__ERROR 'currently in CI, but __EDIT explicitly requires terminal input'
		return 1
	}
	$EDITOR $@ </dev/tty >/dev/tty
}
