${scwryptsmodule}.get-realpath() {
	[[ ! $1 =~ ^[/~] ]] \
		&& echo $(readlink -f "$EXECUTION_DIR/$1") \
		|| echo "$1" \
		;

	return 0
}
