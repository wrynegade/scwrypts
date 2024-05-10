#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		allows batch operations against existing mocks for lib/test/unittest
	"
	eval "$(utils.parse.autosetup)"

	##########################################

	local MOCK
	for MOCK in ${MOCKS[@]}
	do
		${MOCK}.${OPERATION}
	done
}

#####################################################################

${scwryptsmodule}.locals() {
	local OPERATION
}

${scwryptsmodule}.parse() {
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
