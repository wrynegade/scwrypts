#####################################################################

use test/mock/unittest-operations
use test/mock/env

#####################################################################

SCWRYPTS__EXECUTE_ALL_TESTS() {
	local ERRORS=0
	[ "$SCWRYPTS_LOG_LEVEL" ] || SCWRYPTS_LOG_LEVEL=4

	local UNITTESTS=($(echo "${(k)functions}" | sed 's/ /\n/g' | grep '\.test\.' | sort))
	[[ ${#UNITTESTS[@]} -gt 0 ]] \
		|| ERROR "must define at least one unittest" \
		|| return 1

	STATUS "${SCWRYPTS_TEST_MODULE_STRING}starting test suite"

	local UNITTEST_RESULTS_DIR="${SCWRYPTS_TEMP_PATH}/test"
	mkdir -p "${UNITTEST_RESULTS_DIR}"

	local TEST_COUNT=0

	local UNITTEST
	for UNITTEST in ${UNITTESTS[@]}
	do
		((TEST_COUNT+=1))
		command -v beforeeach &>/dev/null && beforeeach

		${UNITTEST} &> "${UNITTEST_RESULTS_DIR}/${UNITTEST}.txt" \
			&& SUCCESS "${SCWRYPTS_TEST_MODULE_STRING}${UNITTEST}" \
			|| { ERROR "${SCWRYPTS_TEST_MODULE_STRING}${UNITTEST}"; cat "${UNITTEST_RESULTS_DIR}/${UNITTEST}.txt"; }

		command -v aftereach &>/dev/null && aftereach

		MOCK_UNITTEST --operation restore
		MOCK__ENV.restore
	done

	local EXIT_CODE=$ERRORS
	[[ $ERRORS -eq 0 ]] \
		&& SUCCESS "${SCWRYPTS_TEST_MODULE_STRING}passed ${TEST_COUNT} / ${TEST_COUNT} test(s)" \
		|| ERROR "${SCWRYPTS_TEST_MODULE_STRING}failed ${EXIT_CODE} / ${TEST_COUNT} test(s)" \
		;

	return $EXIT_CODE
}
