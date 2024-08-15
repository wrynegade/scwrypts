#####################################################################

DEPENDENCIES+=(sed)

#####################################################################

MOCKS=()
MOCK() {
	eval "$(USAGE__reset)"
	local USAGE__description="
		(beta) generates a function mock for basic ZSH unit testing
	"
	local \
		FUNCTION STDOUT STDERR EXIT_CODE \
		PARSERS=(MOCK__PARSER)

	eval "$ZSHPARSEARGS"

	##########################################
	
	export MOCK__ORIGINAL_IMPLEMENTATION__${FUNCTION}="$(which ${FUNCTION})"

	[ "$STDOUT" ] && export MOCK__STDOUT__${FUNCTION}="$STDOUT"
	[ "$STDERR" ] && export MOCK__STDERR__${FUNCTION}="$STDERR"

	[ $EXIT_CODE ] || EXIT_CODE=0
	export MOCK__EXIT_CODE__${FUNCTION}=$EXIT_CODE

	##########################################

	# tricky! in order to set the $FUNCTION as literal within zsh functions, we need
	# to run all the test definitions as an eval line :S
	eval "

	${FUNCTION}() {
		export MOCK__CALLSTACK__${FUNCTION}+=(\"\$@\")
		export MOCK__CALLCOUNT__${FUNCTION}+=(\"\$@\")

		local STDOUT=\$(eval echo '\$MOCK__STDOUT__'${FUNCTION})
		[ \"\$STDOUT\" ] && printf \"\$STDOUT\"

		local STDERR=\$(eval echo '\$MOCK__STDERR__'${FUNCTION})
		[ \"$STDERR\" ] && printf \"$STDERR\" >&2

		return \$(eval echo '\$MOCK__EXIT_CODE__'${FUNCTION})
	}

	${FUNCTION}.assert.calledwith() {
		local ERRORS=0
		local CALLED_ARGS=\"\$@\"
		local CALLED_WITH=false

		local CALL
		for CALL in \${MOCK__CALLSTACK__${FUNCTION}[@]}
		do
			[[ \"\$(eval echo '\$MOCK__CALLSTACK__'${FUNCTION})\" =~ ^\$CALLED_WITH$ ]] \
				&& CALLED_WITH=true
		done

		[[ \$CALLED_WITH =~ true ]] \
			|| ERROR \"${FUNCTION} was not called with '\$CALLED_ARGS'\" \
	}

	${FUNCTION}.assert.called() {
		local ERRORS=0
		[[ MOCK__CALLCOUNT__${FUNCTION} -gt 0 ]] \
			|| ERROR \"${FUNCTION} was not called\"
	}

	${FUNCTION}.assert.not.called() {
		local ERRORS=0
		[[ \$? -ne 0 ]] \
			|| ERROR \"${FUNCTION} was called\"
	}

	${FUNCTION}.reset() {
		unset MOCK__CALLSTACK__${FUNCTION}
	}

	${FUNCTION}.restore() {
		MOCKS=(\$(echo \"\$MOCKS\" | sed 's/\s\+/\n/g' | grep -v \"^${FUNCTION}$\"))
		unset -f \
			${FUNCTION} \
			${FUNCTION}.assert.called \
			${FUNCTION}.assert.not.called \
			${FUNCTION}.reset \
			${FUNCTION}.restore \
			;

		local ORIGINAL_IMPLEMENTATION=\"\$(eval echo '\$MOCK__ORIGINAL_IMPLEMENTATION__'${FUNCTION})\"
		[[ \$(echo \"\$ORIGINAL_IMPLEMENTATION\" | wc -l) -gt 1 ]] \
			&& eval \"\$ORIGINAL_IMPLEMENTATION\"

		unset ORIGINAL__IMPLEMENTATION__${FUNCTION}
	}
	"

	MOCKS+=($FUNCTION)
}

#####################################################################

MOCK__PARSER() {
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

		* ) [[ $POSITIONAL_ARGS -gt 0 ]] && return 0
			((POSITIONAL_ARGS+=1))
			PARSED=1
			case $POSITIONAL_ARGS in
				1 ) FUNCTION="$1" ;;
			esac
			;;
	esac

	return $PARSED
}

MOCK__PARSER__usage() {
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

MOCK__PARSER__validate() {
	[ $FUNCTION ] && command -v $FUNCTION &>/dev/null \
		|| ERROR "cannot mock uncallable '$FUNCTION'"

	echo "$MOCKS" | sed 's/\s\+/\n/g' | grep -q "^${FUNCTION}$" \
		&& ERROR "cannot mock '$FUNCTION' (it is already mocked)"
}
