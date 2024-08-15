
#####################################################################

MOCK_UNITTEST() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		(beta) allows batch operations against existing mocks for lib/test/unittest
	"

	local \
		OPERATION \
		PARSERS=(MOCK_UNITTEST__PARSER)

	eval "$ZSHPARSEARGS"

	##########################################
	
	local MOCK
	for MOCK in ${MOCKS[@]}
	do
		${MOCK}.${OPERATION}
	done
}

#####################################################################

MOCK_UNITTEST__PARSER() {
	# local OPERATION
	local PARSED=0

	case $1 in
		--operation )
			PARSED=2
			OPERATION="$2"
			;;
	esac

	return $PARSED
}

MOCK_UNITTEST__PARSER__usage() {
	USAGE__options+='
		--operation <string>   one of (restore reset) to perform on all active mocks
	'
}

MOCK_UNITTEST__PARSER__validate() {
	case $OPERATION in
		reset | restore ) ;;
		* ) ERROR "invalid or missing operation '$OPERATION'" ;;
	esac
}
