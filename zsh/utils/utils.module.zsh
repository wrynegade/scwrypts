#####################################################################

_DEPENDENCIES+=(fzf) # (extensible) list of PATH dependencies
_REQUIRED_ENV+=()    # (extensible) list of required environment variables

#####################################################################

source ${0:a:h}/io.zsh
source ${0:a:h}/os.zsh
source ${0:a:h}/credits.zsh

#####################################################################

IMPORT_ERROR=0

[ $CI ] && {
	export _AWS_PROFILE="$AWS_PROFILE"
	export _AWS_ACCOUNT="$AWS_ACCOUNT"
	export _AWS_REGION="$AWS_REGION"
}

source ${0:a:h}/dependencies.zsh
_DEP_ERROR=0
_DEPENDENCIES=($(echo $_DEPENDENCIES | sort -u))
__CHECK_DEPENDENCIES $_DEPENDENCIES || _DEP_ERROR=$?

source ${0:a:h}/environment.zsh
_ENV_ERROR=0
_REQUIRED_ENV=($(echo $_REQUIRED_ENV | sort -u))
__CHECK_REQUIRED_ENV $_REQUIRED_ENV || _ENV_ERROR=$?

[[ $_ENV_ERROR -ne 0 ]] && {
	__REMINDER 'to update missing environment variables, run:'
	__REMINDER "'scwrypts zsh/scwrypts/environment/edit'"
}

((IMPORT_ERROR+=$_DEP_ERROR))
((IMPORT_ERROR+=$_ENV_ERROR))

[[ $IMPORT_ERROR -ne 0 ]] && {
	__ERROR "encountered $IMPORT_ERROR import error(s)"
}

#####################################################################
[[ $IMPORT_ERROR -eq 0 ]]
