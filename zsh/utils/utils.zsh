#####################################################################

_DEPENDENCIES+=(fzf) # (extensible) list of PATH dependencies
_REQUIRED_ENV+=()    # (extensible) list of required environment variables

#####################################################################

source ${0:a:h}/io.zsh
source ${0:a:h}/os.zsh
source ${0:a:h}/credits.zsh

#####################################################################

IMPORT_ERROR=0

source ${0:a:h}/dependencies.zsh
_DEPENDENCIES=($(echo $_DEPENDENCIES | sort -u))
__CHECK_DEPENDENCIES $_DEPENDENCIES || ((IMPORT_ERROR+=$?))

source ${0:a:h}/environment.zsh
_REQUIRED_ENV=($(echo $__CHECK_REQUIRED_ENV | sort -u))
__CHECK_REQUIRED_ENV $_REQUIRED_ENV || ((IMPORT_ERROR+=$?))

[[ $IMPORT_ERROR -eq 0 ]] || { 
	__ERROR "encountered $IMPORT_ERROR import error(s)"
	return 1
}

#####################################################################
