#####################################################################

DEPENDENCIES+=(sed)

#####################################################################

#
# "mocking" is critical to unittesting workflows, and although this
# provides a preliminary implementation idea for "mocking" in ZSH,
# this is very new and subject to change
#
# for critical workflows, though, some limited tests are way better
# than no tests at all!
#
# known issues:
#   - callstack assertions are never set when the function call is
#     a non-terminal member of a pipestream; for example:
#
#		unittest.mock func-a --stdout asdf
#
#		func-a | grep -q "asdf"
#		         ^ grep will succeed, indicating the mock worked
#
#		func-a.assert.called
#		       ^ will fail; I guess pipe streams are executed in a subshell
#		                    where export doesn't work as expected?
#

MOCKS=()
${scwryptsmodule}() {
	local DESCRIPTION="
		(beta) generates a function mock for basic ZSH unit testing
	"
	eval "$(utils.parse.autosetup)"

	##########################################

	export MOCK__ORIGINAL_IMPLEMENTATION__${FUNCTION_VARIABLE}="$(which ${FUNCTION})"

	[ "${STDOUT}" ] && export MOCK__STDOUT__${FUNCTION_VARIABLE}="${STDOUT}"
	[ "${STDERR}" ] && export MOCK__STDERR__${FUNCTION_VARIABLE}="${STDERR}"

	[ ${EXIT_CODE} ] || EXIT_CODE=0
	export MOCK__EXIT_CODE__${FUNCTION_VARIABLE}=${EXIT_CODE}

	##########################################

	# tricky! in order to set the ${FUNCTION} as literal within zsh functions, we need
	# to run all the test definitions as an eval line :S

	eval "

	export MOCK__CALLSTACK__${FUNCTION_VARIABLE}=()
	export MOCK__CALLCOUNT__${FUNCTION_VARIABLE}=0

	${FUNCTION}() {
		MOCK__CALLSTACK__${FUNCTION_VARIABLE}+=(\"\$@\")
		((MOCK__CALLCOUNT__${FUNCTION_VARIABLE}+=1))

		printf \"\$MOCK__STDOUT__${FUNCTION_VARIABLE}\"
		printf \"\$MOCK__STDERR__${FUNCTION_VARIABLE}\" >&2

		return \$(eval echo '\$MOCK__EXIT_CODE__'${FUNCTION_VARIABLE})
	}

	${FUNCTION}.assert.called() {
		local ERRORS=0
		[[ MOCK__CALLCOUNT__${FUNCTION_VARIABLE} -gt 0 ]] \
			|| echo.error \"${FUNCTION} was not called\"
	}

	${FUNCTION}.assert.not.called() {
		local ERRORS=0
		${FUNCTION}.assert.called &>/dev/null
		[[ \$? -ne 0 ]] \
			|| echo.error \"${FUNCTION} was called\"
	}

	${FUNCTION}.assert.callstack() {
		local ERRORS=0
		[[ \"\$@\" =~ ^\${MOCK__CALLSTACK__${FUNCTION_VARIABLE}}$ ]] \
			|| echo.error \"${FUNCTION} callstack does not match\nexpected : \$@\nreceived : \${MOCK__CALLSTACK__${FUNCTION_VARIABLE}}\"
	}

	${FUNCTION}.assert.callstackincludes() {
		local ERRORS=0
		[[ \${MOCK__CALLSTACK__${FUNCTION_VARIABLE}} =~ \$@ ]] \
			|| echo.error \"${FUNCTION} callstack does not include\nexpected  : \$@\ncallstack : \${MOCK__CALLSTACK__${FUNCTION_VARIABLE}}\"
	}

	${FUNCTION}.reset() {
		unset \
			MOCK__CALLSTACK__${FUNCTION_VARIABLE} \
			MOCK__CALLCOUNT__${FUNCTION_VARIABLE} \
			;
	}

	${FUNCTION}.restore() {
		MOCKS=(\$(echo \"\$MOCKS\" | sed 's/\s\+/\n/g' | grep -v \"^${FUNCTION}$\"))

		unset \
			MOCK__CALLSTACK__${FUNCTION_VARIABLE} \
			MOCK__CALLCOUNT__${FUNCTION_VARIABLE} \
			;

		unset -f \
			${FUNCTION} \
			${FUNCTION}.assert.called \
			${FUNCTION}.assert.not.called \
			${FUNCTION}.assert.callstack \
			${FUNCTION}.assert.callstackincludes \
			${FUNCTION}.reset \
			${FUNCTION}.restore \
			;

		local ORIGINAL_IMPLEMENTATION=\"\$(eval echo '\$MOCK__ORIGINAL_IMPLEMENTATION__'${FUNCTION_VARIABLE})\"
		[[ \$(echo \"\$ORIGINAL_IMPLEMENTATION\" | wc -l) -gt 1 ]] \
			&& eval \"\$ORIGINAL_IMPLEMENTATION\"

		unset ORIGINAL__IMPLEMENTATION__${FUNCTION_VARIABLE}
	}
	"

	MOCKS+=(${FUNCTION})
}

#####################################################################

${scwryptsmodule}.parse.locals() {
	local FUNCTION
	local FUNCTION_VARIABLE
	local STDOUT
	local STDERR
	local EXIT_CODE
}

${scwryptsmodule}.parse() {
	# local FUNCTION STDOUT STDERR EXIT_CODE
	local PARSED=0

	case $1 in
		--stdout )
			PARSED=2
			STDOUT="$2"
			;;

		--stderr )
			PARSED=2
			STDERR="$2"
			;;

		--exit-code )
			PARSED=2
			EXIT_CODE="$2"
			;;

		* ) [[ ${POSITIONAL_ARGS} -gt 0 ]] && return 0
			((POSITIONAL_ARGS+=1))
			PARSED=1
			case ${POSITIONAL_ARGS} in
				1 ) FUNCTION="$1" ;;
			esac
			;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.parse.usage() {
	USAGE__usage+=' function [...options...]'

	USAGE__args+='
		function   the function to be mocked
	'

	USAGE__options+='
		--stdout <string>      mock the stdout output for the call
		--stderr <string>      mock the stdout output for the call
		--exit-code <number>   mock the exit code for the call
	'
}

${scwryptsmodule}.parse.validate() {
	FUNCTION_VARIABLE="$(echo "${FUNCTION}" | sed 's/\./___/g; s/-/_____/g')"
	[ "${FUNCTION_VARIABLE}" ] || echo.error "failed to determine safe variable name for '${FUNCTION}'"

	[ ${FUNCTION} ] && command -v ${FUNCTION} &>/dev/null || {
		[[ $(eval echo "\$MOCK_UNCALLABLE_WARNING_ISSUED__${FUNCTION_VARIABLE}") =~ true ]] || {
			echo.warning "mocking uncallable '${FUNCTION}'"
			export MOCK_UNCALLABLE_WARNING_ISSUED__${FUNCTION_VARIABLE}=true
		}
	}

	echo "${MOCKS}" | sed 's/\s\+/\n/g' | grep -q "^${FUNCTION}$" \
		&& echo.error "cannot mock '${FUNCTION}' (it is already mocked)"
}
