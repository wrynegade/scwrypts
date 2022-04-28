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
	local Yn; __READ -k Yn; echo
	[[ $Yn =~ [nN] ]] && return 1 || return 0
}

__yN() {
	__PROMPT "$@ [yN]"
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

__FZF()      { fzf -i --height=30% --layout=reverse --prompt "$@ : "; }
__FZF_HEAD() { fzf -i --height=30% --layout=reverse --print-query --prompt "$@ : " | head -n1; }
__FZF_TAIL() { fzf -i --height=30% --layout=reverse --print-query --prompt "$@ : " | tail -n1; }

__READ()  { read $@ </dev/tty; }

__EDIT() { $EDITOR $@ </dev/tty >/dev/tty; }
