#####################################################################

use test/mock/unittest-operations
use test/mock/env

#####################################################################

SCWRYPTS__EXECUTE_ALL_TESTS() {
	local ERRORS=0

	local UNITTESTS=($(echo "${(k)functions}" | sed 's/ /\n/g' | grep '\.test\.'))
	[[ ${#UNITTESTS[@]} -gt 0 ]] \
		|| ERROR "must define at least one unittest" \
		|| return 1

	local UNITTEST
	for UNITTEST in ${UNITTESTS[@]}
	do
		$UNITTEST &>/dev/null \
			&& SUCCESS "$UNITTEST" || ERROR "$UNITTEST"

		MOCK_UNITTEST --operation restore
		MOCK__ENV.restore
	done

	local EXIT_CODE=$ERRORS
	[[ $ERRORS -eq 0 ]] \
		&& SUCCESS "passed tests" \
		|| ERROR "failed $EXIT_CODE test(s)" \
		;

	return $EXIT_CODE
}
