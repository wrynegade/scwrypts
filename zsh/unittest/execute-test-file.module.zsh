#####################################################################

use unittest/operations

#####################################################################

${scwryptsmodule}() {
	local ERRORS=0 TEST_ERRORS=0
	[ "$SCWRYPTS_LOG_LEVEL" ] || SCWRYPTS_LOG_LEVEL=4

	local UNITTESTS=($(echo "${(k)functions}" | sed 's/ /\n/g' | grep '^test\.' | sort))
	[[ ${#UNITTESTS[@]} -gt 0 ]] \
		|| echo.error "must define at least one unittest" \
		|| return 1

	echo.status "${SCWRYPTS_TEST_MODULE_STRING}starting test suite"

	local UNITTEST_RESULTS_DIR="${SCWRYPTS_TEMP_PATH}/test"
	mkdir -p "${UNITTEST_RESULTS_DIR}"

	local TEST_COUNT=0

	command -v beforeall &>/dev/null && beforeall

	local UNITTEST
	for UNITTEST in ${UNITTESTS[@]}
	do
		((TEST_COUNT+=1))
		ERRORS=0
		command -v beforeeach &>/dev/null && beforeeach

		${UNITTEST} &> "${UNITTEST_RESULTS_DIR}/${UNITTEST}.txt" \
			&& echo.success "${SCWRYPTS_TEST_MODULE_STRING}${UNITTEST}" \
			|| { echo.error "${SCWRYPTS_TEST_MODULE_STRING}${UNITTEST}"; ((TEST_ERRORS+=1)); echo "--- begin test output ---">&2; cat "${UNITTEST_RESULTS_DIR}/${UNITTEST}.txt"; echo "--- end test output ---">&2; }

		command -v aftereach &>/dev/null && aftereach

		unittest.operations restore
		unittest.mock.env.restore
	done

	command -v afterall &>/dev/null && afterall

	local EXIT_CODE=$TEST_ERRORS
	[[ $TEST_ERRORS -eq 0 ]] \
		&& echo.success "${SCWRYPTS_TEST_MODULE_STRING}passed ${TEST_COUNT} / ${TEST_COUNT} test(s)" \
		|| echo.error "${SCWRYPTS_TEST_MODULE_STRING}failed ${EXIT_CODE} / ${TEST_COUNT} test(s)" \
		;

	return $EXIT_CODE
}
