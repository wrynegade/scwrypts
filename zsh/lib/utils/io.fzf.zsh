FZF() {
	[ $CI ] && {
		DEBUG "invoked FZF with $@"
		FAIL 1 'currently in CI, but FZF requires user input'
	}

	local FZF_ARGS=()

	FZF_ARGS+=(-i)
	FZF_ARGS+=(--ansi)
	FZF_ARGS+=(--bind=ctrl-c:cancel)
	FZF_ARGS+=(--height=50%)
	FZF_ARGS+=(--layout=reverse)

	local SELECTION=$(fzf ${FZF_ARGS[@]} --prompt "$1 : " ${@:2} 2>/dev/tty)
	PROMPT "$1"

	[ $BE_QUIET ] || {
		[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] && echo $SELECTION >&2
	}
	echo $SELECTION
	[ $SELECTION ]
}

FZF_USER_INPUT() { # allow user to type custom answers; reconfirm if ambiguous with select
	local FZF_OUTPUT=$(BE_QUIET=1 FZF $@ --print-query | sed '/^$/d' | sort -u)
	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] && echo $FZF_OUTPUT | head -n1 >&2
	[ ! $FZF_OUTPUT ] && return 1

	[[ $(echo "$FZF_OUTPUT" | wc -l) -eq 1 ]] \
		&& { echo "$FZF_OUTPUT"; return 0; }

	local FZF_OUTPUT=$(
		echo "$FZF_OUTPUT" \
			| sed "1s/\$/^$(printf "$__LIGHT_GRAY\\033[3m")<- what you typed$(printf $__COLOR_RESET)/" \
			| sed "2s/\$/^$(printf "$__LIGHT_GRAY\\033[3m")<- what you selected$(printf $__COLOR_RESET)/" \
			| column -ts '^' \
			| BE_QUIET=1 FZF "$@ (clarify)" \
		)

	[[ $SCWRYPTS_LOG_LEVEL -ge 1 ]] && echo $FZF_OUTPUT >&2
	FZF_OUTPUT=$(echo $FZF_OUTPUT | sed 's/\s\+<- what you .*$//')
	echo $FZF_OUTPUT
	[ $FZF_OUTPUT ]
}
