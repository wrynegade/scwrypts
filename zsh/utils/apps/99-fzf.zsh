utils.fzf() {
	case "$(normalize.boolean CI)" in
		( true )
			echo.error "currently in CI, but utils.fzf requires user input"
			return 1
			;;
	esac
	##########################################

	local PARSERS=() DESCRIPTION='
		provides a consistent interface to fzf by unifying display settings
		and assigning sensible defaults

		returns 0 only when a non-empty selection is made by the user
	'

	eval "$(utils.parse.autosetup)"

	local DEBUG_ARGS=(-v user_prompt -v quiet -v selection) TRACE_ARGS=(-v fzf_args)

	[[ "${BE_QUIET}" ]] && echo.warning.deprecation v5.3 'use of BE_QUIET= will be removed'

	##########################################

	local selection="$(fzf "${fzf_args[@]}" 2>/dev/tty)"

	echo.trace

	case "${quiet}" in
		( true  ) ;;
		( false ) echo.prompt "${user_prompt}" --response "${(q)selection}" ;;
	esac

	echo "${selection}"
	[[ "${selection}" ]]
}

utils.fzf.parse.locals() {
	local fzf_args=(-i --ansi --bind=ctrl-c:cancel --height=50% --layout=reverse)
	local user_prompt
	local user_prompt_delimiter=' : '
	local quiet="${BE_QUIET:-false}"
}

utils.fzf.parse() {
	local parsed=0

	case "${1}" in
		( --prompt ) parsed=2
			# add the user prompt back in as args to fzf
			[[ "${user_prompt}" ]] && fzf_args+=("${user_prompt}")

			user_prompt="${2}"
			;;

		( --quiet ) parsed=1
			quiet=true
			;;

		( * ) parsed=1
			case "$((POSITIONAL_ARGS+=1))" in
				( 1 ) [[ "${user_prompt}" ]] && fzf_args+=("${1}") || user_prompt="${1}" ;;
				( * ) fzf_args+=("${1}") ;;
			esac
			;;
	esac

	return "${parsed}"
}

utils.fzf.parse.validate() {
	[[ "${user_prompt}" ]] || user_prompt='make a selection'
	fzf_args+=(--prompt "${user_prompt}${user_prompt_delimiter}")
}

#####################################################################

utils.fzf.user-input() {  # allow user to type custom answers; reconfirm if ambiguous with select
	local fzf_output="$(utils.fzf "${@}" --quiet --print-query | grep . | sort -u)"
	[[ "${fzf_output}" ]] || return 1

	# only 1 line = non-ambiguous
	[[ $(echo "${fzf_output}" | wc -l) -eq 1 ]] \
		&& echo "${fzf_output}" \
		&& return 0

	local fzf_output="$(
		echo "${fzf_output}" \
			| sed "1s/\$/^$(utils.colors.print light-gray '<- what you typed')/" \
			| sed "2s/\$/^$(utils.colors.print light-gray '<- what you selected')/" \
			| column -ts '^' \
			| utils.fzf --quiet "${@}" '(clarify)' \
			| sed 's/\s\+<- what you .*$//' \
	)"

	echo "${fzf_output}"
	[[ "${fzf_output}" ]]
}

#####################################################################

utils.fzf.file-select() {
	local PARSERS=() DESCRIPTION='
		given a directory, provides a user-friendly file selection interface
	'

	eval "$(utils.parse.autosetup)"

	##########################################

	local fzf_output="$(
		cd -- "${directory}"
		find . "${find_args[@]}" \
			| sed 's|^\./||' \
			| utils.fzf "${fzf_args[@]}" \
	)"

	[[ "${fzf_output}" ]] && fzf_output="${directory}/${fzf_output}"

	echo "${fzf_output}"
	[[ "${fzf_output}" ]]
}

utils.fzf.file-select.parse.locals() {
	local ARGS=()
	local directory
	local user_prompt
	local fzf_args=()
	local find_args=()
	local filetypes=()
	local mindepth=1
	local maxdepth=1
}

utils.fzf.file-select.parse() {
	local parsed=0

	case "${1}" in
		( -t | --filetype ) parsed=2; filetypes+=("${2}") ;;
		( -p | --prompt   ) parsed=2; user_prompt="${2}"  ;;

		( --mindepth ) parsed=2; mindepth="${2}" ;;
		( --maxdepth ) parsed=2; maxdepth="${2}" ;;
	esac

	return "${parsed}"
}

utils.fzf.file-select.parse.usage() {
	USAGE__options+='
		-t, --filetype <ext>    file extension to include; multiple can be specified
		-p, --prompt <string>   fzf prompt to the user (default: "select a file from ${directory}")

		--mindepth <number>   minimum find depth; unset with 0 (default: 1)
		--maxdepth <number>   maximum find depth; unset with 0 (default: 1)
	'

	USAGE__args+='
		$1       the directory to target
		$2..$N   remaining arguments are forwarded to utils.fzf
	'
}

utils.fzf.file-select.parse.validate() {
	directory="$(readlink --canonicalize -- "${ARGS[1]}")"
	[[ "${directory}" ]] && [[ -d "${directory}" ]] \
		|| echo.error "missing or invalid directory '${ARGS[1]}'" -v directory

	[[ "${user_prompt}" ]] || user_prompt="select a file from ${directory}"
	fzf_args=(--prompt "${user_prompt}" "${ARGS[@]:1}")

	[[ "${mindepth}" -le "${maxdepth}" ]] \
		|| echo.error "invalid min/max depth setting: mindepth=${(q)mindepth} maxdepth=${(q)maxdepth}"

	local depth_flag
	for depth_flag in mindepth maxdepth
	do
		case "${(P)depth_flag}" in
			( 0 ) ;;
			( * ) find_args+=("-${depth_flag}" "${(P)depth_flag}")
		esac
	done

	find_args+=(-type f)

	local filetype
	for filetype in "${filetypes[@]}"
	do
		find_args+=(-o -name "\*.${filetype}" -o -name "\*.${filetype:u}")
	done
}
