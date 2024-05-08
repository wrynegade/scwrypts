[[ $SCWRYPTS_IMPORT_DRIVER_READY -eq 1 ]] && return 0
 ###################################################################
#                                                                   #
# usage: use [OPTIONS ...] zsh/module/path                          #
#                                                                   #
 ###################################################################
#                                                                   #
# OPTIONS:                                                          #
#                                                                   #
#   -g, --group          lookup library root from friendly group    #
#                        name (requires configuration)              #
#                        (default: scwrypts)                        #
#                                                                   #
#   -r, --library-root   fully qualified path to a library root     #
#                                                                   #
#   --check-environment  check environment immediately rather than  #
#                        wait for downstream CHECK_ENVIRONMENT call #
#                                                                   #
#                                                                   #
# Allows for import-style library loading in zsh. No matter what    #
# scwrypt is run, this function (and required helpers) are *also*   #
# loaded, ensuring that 'use' is always available in scwrypts       #
# context.                                                          #
#                                                                   #
#                                                                   #
# Friendly group-names can be configured by setting the variable    #
# 'SCWRYPTS_LIBRARY_ROOT__<group-name>' to the fully qualified path #
# to the root directory of the modules library.                     #
#                                                                   #
#                                                                   #
 ###################################################################

source "${0:a:h}/config.zsh"

use() {
	local SCWRYPTS_LIBRARY SCWRYPTS_LIBRARY_ROOT SCWRYPTS_LIBRARY_GROUP
	local DEFER_ENVIRONMENT_CHECK=true

	while [[ $# -gt 0 ]]
	do
		case $1 in
			-g | --group )
				[ $SCWRYPTS_LIBRARY_ROOT ] && ERROR 'specify only one of {(-g), (-r)}'
				SCWRYPTS_LIBRARY_GROUP=$2
				shift 1
				;;
			-r | --library-root )
				[ $SCWRYPTS_LIBRARY_GROUP ] && ERROR 'specify only one of {(-g), (-r)}'
				SCWRYPTS_LIBRARY_ROOT=$2
				shift 1
				;;
			-c | --check-environment )
				DEFER_ENVIRONMENT_CHECK=false
				;;
			* )
				[ ! $SCWRYPTS_LIBRARY ] \
					&& SCWRYPTS_LIBRARY=$1 \
					|| ERROR 'too many arguments; expected exactly 1 argument' \

				;;
		esac
		shift 1
	done

	[ ! $SCWRYPTS_LIBRARY ] && ERROR 'no library specified for import'

	: \
		&& [ ! $SCWRYPTS_LIBRARY_GROUP ] \
		&& [ ! $SCWRYPTS_LIBRARY_ROOT  ] \
		&& SCWRYPTS_LIBRARY_GROUP=scwrypts

	[ ! $SCWRYPTS_LIBRARY_ROOT ] && SCWRYPTS_LIBRARY_ROOT=$(GET_SCWRYPTS_LIBRARY_ROOT)
	[ ! $SCWRYPTS_LIBRARY_ROOT ] && ERROR "unable to determine library root from group name '$SCWRYPTS_LIBRARY_GROUP'"

	#####################################################################

	local LIBRARY_FILE LIBRARY_FILE_TEMP

	[ ! $LIBRARY_FILE ] \
		&& LIBRARY_FILE_TEMP="$SCWRYPTS_LIBRARY_ROOT/$SCWRYPTS_LIBRARY.module.zsh" \
		&& [ -f "$LIBRARY_FILE_TEMP" ] \
		&& LIBRARY_FILE="$LIBRARY_FILE_TEMP"

	[ ! $LIBRARY_FILE ] \
		&& LIBRARY_FILE_TEMP="$SCWRYPTS_LIBRARY_ROOT/$SCWRYPTS_LIBRARY/$(echo $SCWRYPTS_LIBRARY | sed 's/.*\///').module.zsh" \
		&& [ -f "$LIBRARY_FILE_TEMP" ] \
		&& LIBRARY_FILE="$LIBRARY_FILE_TEMP" \

	[ ! $LIBRARY_FILE ] \
		&& ERROR "no such library '$SCWRYPTS_LIBRARY_GROUP/$SCWRYPTS_LIBRARY'"

	#####################################################################

	CHECK_ERRORS --no-fail || {
		((IMPORT_ERRORS+=1))
		return 1
	}

	#####################################################################

	IS_LOADED && return 0

	source "$LIBRARY_FILE" || {
		((IMPORT_ERRORS+=1))
		ERROR "import error for '$SCWRYPTS_LIBRARY_GROUP/$SCWRYPTS_LIBRARY'"
		return 1
	}

	[[ $DEFER_ENVIRONMENT_CHECK =~ false ]] && {
		CHECK_ENVIRONMENT || {
			((IMPORT_ERRORS+=1))
			ERROR "import error for '$SCWRYPTS_LIBRARY_GROUP/$SCWRYPTS_LIBRARY'"
			return 1
		}
	}

	IS_LOADED --set
}

GET_SCWRYPTS_LIBRARY_ROOT() {
	local ROOT

	ROOT=$(eval echo '$SCWRYPTS_LIBRARY_ROOT__'$SCWRYPTS_LIBRARY_GROUP)
	[ $ROOT ] && echo $ROOT && return 0

	[[ $(eval echo '$SCWRYPTS_TYPE__'$SCWRYPTS_LIBRARY_GROUP) =~ zsh ]] \
		&& ROOT=$(eval echo '$SCWRYPTS_ROOT__'$SCWRYPTS_LIBRARY_GROUP/lib) \
		|| ROOT=$(eval echo '$SCWRYPTS_ROOT__'$SCWRYPTS_LIBRARY_GROUP/zsh/lib) \
		;
	[ $ROOT ] && echo $ROOT && return 0
}

IS_LOADED() {
	local VARIABLE_NAME="SCWRYPTS_LIBRARY_LOADED__${SCWRYPTS_LIBRARY_GROUP}__$(echo $SCWRYPTS_LIBRARY | sed 's|[/-]|_|g')"

	[[ $1 =~ ^--set$ ]] \
		&& eval $VARIABLE_NAME=1 \

	[[ $(eval echo '$'$VARIABLE_NAME || echo 0) -eq 1 ]]
}


# temporary definitions for first load
CHECK_ERRORS()      { return 0; unset -f CHECK_ERRORS; }
CHECK_ENVIRONMENT() { return 0; unset -f CHECK_ENVIRONMENT; }
ERROR()             { echo $@ >&2; exit 1; }

#####################################################################

# ensures that zsh/utils and zsh/scwrypts/meta are always present!

use utils
use scwrypts/meta

#####################################################################
SCWRYPTS_IMPORT_DRIVER_READY=1
