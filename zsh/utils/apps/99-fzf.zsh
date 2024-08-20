utils.fzf() {
	[ ${CI} ] && utils.fail 1 'currently in CI, but utils.fzf requires user input'

	local FZF_ARGS=(
		-i
		--ansi
		--bind=ctrl-c:cancel
		--height=50%
		--layout=reverse
		)


	local SELECTION=$(fzf ${FZF_ARGS[@]} --prompt "$1 : " ${@:2} 2>/dev/tty)
	echo.prompt "$1"

	[ ${BE_QUIET} ] || {
		[[ ${SCWRYPTS_LOG_LEVEL} -ge 1 ]] && echo ${SELECTION} >&2
	}
	echo ${SELECTION}
	[ ${SELECTION} ]
}

utils.fzf.user-input() { # allow user to type custom answers; reconfirm if ambiguous with select
	local FZF_OUTPUT=$(BE_QUIET=1 FZF $@ --print-query | sed '/^$/d' | sort -u)
	[[ ${SCWRYPTS_LOG_LEVEL} -ge 1 ]] && echo ${FZF_OUTPUT} | head -n1 >&2
	[ ! ${FZF_OUTPUT} ] && return 1

	[[ $(echo "${FZF_OUTPUT}" | wc -l) -eq 1 ]] \
		&& { echo "${FZF_OUTPUT}"; return 0; }

	local FZF_OUTPUT=$(
		echo "${FZF_OUTPUT}" \
			| sed "1s/\$/^$(utils.colors.print light-gray '<- what you typed')/" \
			| sed "2s/\$/^$(utils.colors.print light-gray '<- what you selected')/" \
			| column -ts '^' \
			| BE_QUIET=1 utils.fzf "$@ (clarify)" \
		)

	[[ ${SCWRYPTS_LOG_LEVEL} -ge 1 ]] && echo ${FZF_OUTPUT} >&2
	FZF_OUTPUT=$(echo ${FZF_OUTPUT} | sed 's/\s\+<- what you .*$//')
	echo ${FZF_OUTPUT}
	[ ${FZF_OUTPUT} ]
}
