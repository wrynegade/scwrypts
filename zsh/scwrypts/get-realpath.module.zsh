${scwryptsmodule}() {
	#
	# returns the fully-qualified path from a user-specified, relative reference
	#                  (allows for '--input-file ./my-file' on the command-line)
	#
	# also uses 'readlink --canonicalize' to read through symlinks to the realpath
	#

	[ "$1" ] || return 1

	[[ ! $1 =~ ^[/~] ]] \
		&& echo $(readlink --canonicalize -- "${EXECUTION_DIR}/$1") \
		|| echo "$1" \
		;

	return 0
}
