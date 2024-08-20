#####################################################################

${scwryptsmodule}() {
	eval "$(usage.reset)"
	local USAGE__description="
		allows batch operations against existing mocks for lib/test/unittest
	"
	local \
		OPERATION \
		PARSERS=()

	eval "$ZSHPARSEARGS"

	##########################################

	local MOCK
	for MOCK in ${MOCKS[@]}
	do
		${MOCK}.${OPERATION}
	done
}

#####################################################################

${scwryptsmodule}.parse() {
	# local OPERATION
	local PARSED=0

	case $1 in
		( restore | reset ) PARSED=1; OPERATION="$1" ;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.parse.usage() {
	USAGE__args+='
		$1   one of (restore reset) to perform on all active mocks
	'
}
