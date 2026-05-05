DEPENDENCIES+=(readlink envsubst)

${scwryptsmodule}() {
	#
	# returns the fully-qualified path from a user-specified, relative reference
	#                  (allows for '--input-file ./my-file' on the command-line)
	#
	# also uses 'readlink --canonicalize' to read through symlinks to the realpath
	#
	local DEBUG_ARGS=() TRACE_ARGS=(-v path_0_raw -v path_1_evaluated -v path_2_target)

	local path_0_raw="${1}"
	local path_1_evaluated="$(echo "${1}" | envsubst)"
	local path_2_target="$(
		case "${path_1_evaluated}" in
			( /* | ~/* ) echo "${path_1_evaluated}" ;;
			( * ) echo "${EXECUTION_DIR}/${path_1_evaluated}" ;;
		esac
	)"

	echo.trace

	[[ "${path_2_target}" ]] || return 1

	readlink --canonicalize -- "${path_2_target}"
}
