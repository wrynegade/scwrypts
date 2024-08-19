[[ ${SCWRYPTS_IMPORT_DRIVER_READY} =~ true ]] && return 0
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
# 'SCWRYPTS_GROUP_CONFIGRUATION__<group-name>__root' to the fully   #
# qualified path to the root directory of the modules library.      #
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
				[ "${SCWRYPTS_LIBRARY_ROOT}" ] && echo.error 'specify only one of {(-g), (-r)}'
				SCWRYPTS_LIBRARY_GROUP=$2
				shift 1
				;;

			-r | --library-root )
				[ "${SCWRYPTS_LIBRARY_GROUP}" ] && echo.error 'specify only one of {(-g), (-r)}'
				SCWRYPTS_LIBRARY_ROOT=$2
				shift 1
				;;

			-c | --check-environment )
				DEFER_ENVIRONMENT_CHECK=false
				;;

			* )
				[ ! "${SCWRYPTS_LIBRARY}" ] \
					&& SCWRYPTS_LIBRARY=$1 \
					|| echo.error 'too many arguments; expected exactly 1 argument' \

				;;
		esac
		shift 1
	done

	[ ! "${SCWRYPTS_LIBRARY}" ] && echo.error 'no library specified for import'

	: \
		&& [ ! "${SCWRYPTS_LIBRARY_GROUP}" ] \
		&& [ ! "${SCWRYPTS_LIBRARY_ROOT}"  ] \
		&& SCWRYPTS_LIBRARY_GROUP=scwrypts

	[ ! "${SCWRYPTS_LIBRARY_ROOT}" ] && SCWRYPTS_LIBRARY_ROOT="$(GET_SCWRYPTS_LIBRARY_ROOT)"
	[ ! "${SCWRYPTS_LIBRARY_ROOT}" ] && echo.error "unable to determine library root from group name '${SCWRYPTS_LIBRARY_GROUP}'"

	#####################################################################

	local LIBRARY_FILE LIBRARY_FILE_TEMP

	local LIBRARY_FILENAME_DIRECT="${SCWRYPTS_LIBRARY_ROOT}/${SCWRYPTS_LIBRARY}.module.zsh"
	local LIBRARY_FILENAME_GROUP_MODULE="${SCWRYPTS_LIBRARY_ROOT}/${SCWRYPTS_LIBRARY}/$(basename -- "${SCWRYPTS_LIBRARY}").module.zsh" \

	for LIBRARY_FILE_TEMP in \
		"${LIBRARY_FILENAME_DIRECT}" \
		"${LIBRARY_FILENAME_GROUP_MODULE}" \
		;
	do
		[ -f "${LIBRARY_FILE_TEMP}" ] && LIBRARY_FILE="${LIBRARY_FILE_TEMP}" && break
	done

	[ "${LIBRARY_FILE}" ] \
		|| echo.error "no such library '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"

	#####################################################################

	local SCWRYPTS_MODULE_BEFORE=${scwryptsmodule}
	[[ ${SCWRYPTS_LIBRARY_GROUP} =~ ^scwrypts$ ]] \
		&& export scwryptsmodule="$(echo "${SCWRYPTS_LIBRARY}" | sed 's|/|.|g')" \
		|| export scwryptsmodule="${SCWRYPTS_LIBRARY_GROUP}.$(echo "${SCWRYPTS_LIBRARY}" | sed 's|/|.|g')" \
		;

	#####################################################################

	CHECK_ERRORS --no-fail || {
		((IMPORT_ERRORS+=1))
		return 1
	}

	#####################################################################

	IS_LOADED && {
		export scwryptsmodule=${SCWRYPTS_MODULE_BEFORE}
		return 0
	}

	source "${LIBRARY_FILE}" || {
		((IMPORT_ERRORS+=1))
		echo.error "import error for '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"
		export scwryptsmodule=${SCWRYPTS_MODULE_BEFORE}
		return 1
	}

	[[ ${DEFER_ENVIRONMENT_CHECK} =~ false ]] && {
		CHECK_ENVIRONMENT || {
			((IMPORT_ERRORS+=1))
			echo.error "import error for '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"
			return 1
		}
	}

	IS_LOADED --set
	[[ ${SCWRYPTS_MODULE_BEFORE} ]] \
		&& export scwryptsmodule=${SCWRYPTS_MODULE_BEFORE} \
		|| unset scwryptsmodule \
		;

	return 0
}

GET_SCWRYPTS_LIBRARY_ROOT() {
	local ROOT

	ROOT="$(scwrypts.config.group "${SCWRYPTS_LIBRARY_GROUP}" zshlibrary)"
	[ "${ROOT}" ] && echo "${ROOT}" && return 0

	##########################################
	
	local GROUP_ROOT="$(scwrypts.config.group "${SCWRYPTS_LIBRARY_GROUP}" root)"
	local GROUP_TYPE="$(scwrypts.config.group "${SCWRYPTS_LIBRARY_GROUP}" type)"

	[[ ${GROUP_TYPE} =~ zsh ]] \
		&& ROOT="${GROUP_ROOT}/lib" \
		|| ROOT="${GROUP_ROOT}/zsh/lib" \
		;

	[ -d "${ROOT}" ] || ROOT="$(dirname -- "${ROOT}")"

	[ "${ROOT}" ] && [ -d "${ROOT}" ] \
		|| echo.error "unable to determine library root" \
		|| return 1

	echo "${ROOT}"
}

IS_LOADED() {
	local VARIABLE_NAME="SCWRYPTS_LIBRARY_LOADED__${SCWRYPTS_LIBRARY_GROUP}__$(echo ${SCWRYPTS_LIBRARY} | sed 's|[/-]|_|g')"

	[[ $1 =~ ^--set$ ]] && eval ${VARIABLE_NAME}=true

	[[ ${(P)VARIABLE_NAME} =~ true ]]
}

#####################################################################

# temporary definitions for first load
CHECK_ERRORS()      { return 0; unset -f CHECK_ERRORS; }
CHECK_ENVIRONMENT() { return 0; unset -f CHECK_ENVIRONMENT; }
ERROR()             { echo $@ >&2; exit 1; }

#####################################################################

# ensures that zsh/utils and zsh/scwrypts/meta are always present!

use utils
use scwrypts/meta

#####################################################################
SCWRYPTS_IMPORT_DRIVER_READY=true
