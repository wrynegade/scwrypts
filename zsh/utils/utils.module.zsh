#####################################################################

DEPENDENCIES+=(fzf) # (extensible) list of PATH dependencies
REQUIRED_ENV+=()    # (extensible) list of required environment variables

#####################################################################

source ${0:a:h}/colors.zsh
source ${0:a:h}/io.zsh
source ${0:a:h}/os.zsh
source ${0:a:h}/credits.zsh
source ${0:a:h}/parse.zsh

#####################################################################

source ${0:a:h}/dependencies.zsh
source ${0:a:h}/environment.zsh

#####################################################################

CHECK_ENVIRONMENT() {
	local OPTIONAL=0

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--optional ) OPTIONAL=1 ;;
		esac
		shift 1
	done

	[[ $OPTIONAL -eq 1 ]] && E=echo.warning || E=ERROR

	local ENVIRONMENT_STATUS=0

	__CHECK_DEPENDENCIES $DEPENDENCIES
	local MISSING_DEPENDENCIES=$?

	__CHECK_REQUIRED_ENV $REQUIRED_ENV
	local MISSING_ENVIRONMENT_VARIABLES=$?

	##########################################

	local ERROR_MESSAGE=""
	[[ $MISSING_DEPENDENCIES -ne 0 ]] && {
		((ENVIRONMENT_STATUS+=1))
		ERROR_MESSAGE+="\n$MISSING_DEPENDENCIES missing "

		[[ $MISSING_DEPENDENCIES -eq 1 ]] \
			&& ERROR_MESSAGE+='dependency' \
			|| ERROR_MESSAGE+='dependencies' \
			;
	}

	[[ $MISSING_ENVIRONMENT_VARIABLES -ne 0 ]] && {
		((ENVIRONMENT_STATUS+=2))
		ERROR_MESSAGE+="\n$MISSING_ENVIRONMENT_VARIABLES missing environment variable"

		[[ $MISSING_ENVIRONMENT_VARIABLES -gt 1 ]] && ERROR_MESSAGE+=s
	}

	[ $IMPORT_ERRORS ] && [[ $IMPORT_ERRORS -ne 0 ]] && {
		((ENVIRONMENT_STATUS+=4))
		ERROR_MESSAGE+="\n$IMPORT_ERRORS import error"

		[[ $IMPORT_ERRORS -gt 1 ]] && ERROR_MESSAGE+=s
	}

	##########################################

	[[ ENVIRONMENT_echo.status -ne 0 ]] && [[ $OPTIONAL -eq 0 ]] && {
		ERROR_MESSAGE=$(echo $ERROR_MESSAGE | sed '1d; s/^/   /')
		$E "environment errors found (see above)\n$ERROR_MESSAGE"
	}

	[[ $MISSING_ENVIRONMENT_VARIABLES -ne 0 ]] && [[ $__SCWRYPT ]] && {
		echo.reminder "
			to quickly update missing environment variables, run:
			'scwrypts zsh/scwrypts/environment/edit'
		"
	}

	[[ $ENVIRONMENT_echo.status -ne 0 ]] && [[ $NO_EXIT -ne 1 ]] && [[ $OPTIONAL -eq 0 ]] && {
		exit $ENVIRONMENT_STATUS
	}

	return $ENVIRONMENT_STATUS
}

CHECK_ENVIRONMENT
