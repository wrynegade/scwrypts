command -v use use.is-loaded use.get-library-root &>/dev/null && return 0

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
#                        wait for downstream call to                #
#                                          utils.check-environment  #
#                                                                   #
#                                                                   #
# ZSHIMPORT_USE_CACHE (true|false; default: true)                   #
#    setting this to false will always require direct, source files #
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

[ ${ZSHIMPORT_USE_CACHE} ] || export ZSHIMPORT_USE_CACHE=true

[[ ${ZSHIMPORT_USE_CACHE} =~ true ]] && {
	command -v jo jq sha1sum &>/dev/null || {
		echo.warning "missing utilities prevents import cache"
		export ZSHIMPORT_USE_CACHE=false
	}
}

[ ${ZSHIMPORT_CACHE_DIR} ] || export ZSHIMPORT_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/zshimport"

source "${0:a:h}/config.zsh"

use() {
	local SCWRYPTS_LIBRARY SCWRYPTS_LIBRARY_ROOT SCWRYPTS_LIBRARY_GROUP
	local DEFER_ENVIRONMENT_CHECK=true

	local ONLY_OUTPUT_METADATA=false
	local ONLY_GENERATE_CACHE=false

	while [[ $# -gt 0 ]]
	do
		case $1 in
			( -g | --group )
				[ "${SCWRYPTS_LIBRARY_ROOT}" ] && echo.error 'specify only one of {(-g), (-r)}'
				SCWRYPTS_LIBRARY_GROUP=$2
				shift 1
				;;

			( -r | --library-root )
				[ "${SCWRYPTS_LIBRARY_GROUP}" ] && echo.error 'specify only one of {(-g), (-r)}'
				SCWRYPTS_LIBRARY_ROOT=$2
				shift 1
				;;

			( -c | --check-environment )
				DEFER_ENVIRONMENT_CHECK=false
				;;

			( --meta )
				ONLY_OUTPUT_METADATA=true
				;;

			( --generate-cache )
				ONLY_GENERATE_CACHE=true
				;;

			( * )
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

	# bail ASAP, check errors later
	use.is-loaded && [[ ${ONLY_OUTPUT_METADATA} =~ false ]] && [[ ${ONLY_GENERATE_CACHE} =~ false ]] && return 0

	[ ! "${SCWRYPTS_LIBRARY_ROOT}" ] && SCWRYPTS_LIBRARY_ROOT="$(use.get-scwrypts-library-root)"
	[ ! "${SCWRYPTS_LIBRARY_ROOT}" ] && echo.error "unable to determine library root from group name '${SCWRYPTS_LIBRARY_GROUP}'"

	#####################################################################

	local LIBRARY_FILE LIBRARY_FILE_TEMP CACHE_FILE

	[ ! "${LIBRARY_FILE}" ] && {
		LIBRARY_FILE_TEMP="${SCWRYPTS_LIBRARY_ROOT}/${SCWRYPTS_LIBRARY}.module.zsh"
		[ -f "${LIBRARY_FILE_TEMP}" ] && {
			LIBRARY_FILE="${LIBRARY_FILE_TEMP}"
			CACHE_FILE="${SCWRYPTS_LIBRARY}.module.zsh"
		}
	}

	[ ! "${LIBRARY_FILE}" ] && {  # "group" library reference
		LIBRARY_FILE_TEMP="${SCWRYPTS_LIBRARY_ROOT}/${SCWRYPTS_LIBRARY}/$(basename -- "${SCWRYPTS_LIBRARY}").module.zsh"
		[ -f "${LIBRARY_FILE_TEMP}" ] && {
			LIBRARY_FILE="${LIBRARY_FILE_TEMP}"
			CACHE_FILE="${SCWRYPTS_LIBRARY}/$(basename -- "${SCWRYPTS_LIBRARY}").module.zsh"
		}
	}

	[ "${LIBRARY_FILE}" ] \
		|| echo.error "no such library '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"

	#####################################################################

	local LIBRARY_HASH LIBRARY_CACHE_DIR LIBRARY_CACHE_FILE

	#####################################################################

	utils.check-errors || {
		((IMPORT_ERRORS+=1))
		return 1
	}

	#####################################################################

	local SCWRYPTS_MODULE_BEFORE=${scwryptsmodule}
	[[ ${SCWRYPTS_LIBRARY_GROUP} =~ ^scwrypts$ ]] \
		&& export scwryptsmodule="$(echo "${SCWRYPTS_LIBRARY}" | sed 's|/|.|g')" \
		|| export scwryptsmodule="${SCWRYPTS_LIBRARY_GROUP}.$(echo "${SCWRYPTS_LIBRARY}" | sed 's|/|.|g')" \
		;

	[[ ${ONLY_OUTPUT_METADATA} =~ true ]] && {
		use.get-metadata
		return 0
	}

	case "${ZSHIMPORT_USE_CACHE}" in
		( false ) ;;
		( true )
			LIBRARY_HASH="$(use.compute-scwrypts-library-hash)"
			LIBRARY_CACHE_DIR="${ZSHIMPORT_CACHE_DIR}/${SCWRYPTS_LIBRARY_GROUP}-${LIBRARY_HASH}"
			LIBRARY_CACHE_FILE="${LIBRARY_CACHE_DIR}/${CACHE_FILE}"

			[ "${LIBRARY_HASH}" ] && [ "${LIBRARY_CACHE_DIR}" ] && [ "${LIBRARY_CACHE_FILE}" ] \
				|| echo.error "error when computing library hash for ${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}"

			use.generate-cache \
				|| echo.error "error generating cache for ${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}" \
				|| return 1
			;;
	esac

	[[ ${ONLY_GENERATE_CACHE} =~ true ]] && {
		cat "${LIBRARY_CACHE_FILE}" | grep .
		return $?
	}

	case ${ZSHIMPORT_USE_CACHE} in
		( true )
			source "${LIBRARY_CACHE_FILE}" || {
				((IMPORT_ERRORS+=1))
				echo.error "import error for '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"
				echo.debug "cache : '${LIBRARY_CACHE_FILE}'"
				return 1
			}
			;;

		( false )

			source "${LIBRARY_FILE}" || {
				((IMPORT_ERRORS+=1))
				echo.error "import error for '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"
				export scwryptsmodule=${SCWRYPTS_MODULE_BEFORE}
				return 1
			}

			[[ ${DEFER_ENVIRONMENT_CHECK} =~ false ]] && {
				utils.check-environment || {
					((IMPORT_ERRORS+=1))
					echo.error "import error for '${SCWRYPTS_LIBRARY_GROUP}/${SCWRYPTS_LIBRARY}'"
					return 1
				}
			}

			use.is-loaded --set
			[[ ${SCWRYPTS_MODULE_BEFORE} ]] \
				&& export scwryptsmodule=${SCWRYPTS_MODULE_BEFORE} \
				|| unset scwryptsmodule \
				;
			;;
	esac

	return 0
}

use.get-scwrypts-library-root() {
	local VARIABLE_NAME="SCWRYPTS_LIBRARY_ROOT__${SCWRYPTS_LIBRARY_GROUP}"
	echo "${(P)VARIABLE_NAME}" | grep . && return 0

	##########################################

	local ROOT

	ROOT="$(scwrypts.config.group "${SCWRYPTS_LIBRARY_GROUP}" zshlibrary)"
	[ "${ROOT}" ] && eval ${VARIABLE_NAME}="${ROOT}" && echo "${ROOT}" && return 0

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

	eval ${VARIABLE_NAME}="${ROOT}"
	echo "${ROOT}"
}

use.compute-scwrypts-library-hash() {
	LC_ALL=POSIX find "${SCWRYPTS_LIBRARY_ROOT}" -type f -name \*.module.zsh -print0 \
		| sort -z \
		| xargs -0 sha1sum \
		| sha1sum \
		| awk '{print $1;}' \
		;
}

use.is-loaded() {
	local VARIABLE_NAME="SCWRYPTS_LIBRARY_LOADED__${SCWRYPTS_LIBRARY_GROUP}__$(echo ${SCWRYPTS_LIBRARY} | sed 's|[/-]|_|g')"

	[[ $1 =~ ^--set$ ]] && eval ${VARIABLE_NAME}=true

	[[ ${(P)VARIABLE_NAME} =~ true ]]
}

use.get-metadata() {
	jo \
		LIBRARY_FILE="${LIBRARY_FILE}" \
		SCWRYPTS_LIBRARY_GROUP="${SCWRYPTS_LIBRARY_GROUP}" \
		SCWRYPTS_LIBRARY="${SCWRYPTS_LIBRARY}" \
		scwryptsmodule="${scwryptsmodule}" \
		;
}

#####################################################################

use.generate-cache() {
	[ "${LIBRARY_CACHE_FILE}" ] || return 1

	[ -f "${LIBRARY_CACHE_FILE}" ] && return 0

	##########################################

	mkdir -p -- "$(dirname -- "${LIBRARY_CACHE_FILE}")"

	local IMPORTS=":${LIBRARY_FILE}:"

	use.generate-cache.create-import $(use.get-metadata) > "${LIBRARY_CACHE_FILE}"

	local METADATA SUBFILE SUBMODULE
	while $(grep -q '^use\s' "${LIBRARY_CACHE_FILE}")
	do
		NEXT_IMPORT=$(grep '^use\s' ${LIBRARY_CACHE_FILE} | head -n1)
		METADATA="$(eval "${NEXT_IMPORT} --meta")"

		SUBFILE="$(echo "${METADATA}" | jq -r .LIBRARY_FILE)"
		[[ "${IMPORTS}" =~ ":${SUBFILE}:" ]] && {
			grep -v "^${NEXT_IMPORT}$" "${LIBRARY_CACHE_FILE}" > "${LIBRARY_CACHE_FILE}.tmp"
			mv "${LIBRARY_CACHE_FILE}.tmp" "${LIBRARY_CACHE_FILE}"
			continue
		}

		IMPORTS+="${SUBFILE}:"

		SUBMODULE="$(echo "${METADATA}" | jq -r .scwryptsmodule)"
		use.generate-cache.create-import "${METADATA}" > "${LIBRARY_CACHE_FILE}.subfile"

		{
			sed -n '0,/^use\s/p' ${LIBRARY_CACHE_FILE} | sed '$d'
			echo '() {'
			cat "${LIBRARY_CACHE_FILE}.subfile"
			echo '}'
			sed -n '/^use\s/,$p' ${LIBRARY_CACHE_FILE} | sed '1d'
		} > "${LIBRARY_CACHE_FILE}.tmp"
		mv "${LIBRARY_CACHE_FILE}.tmp" "${LIBRARY_CACHE_FILE}"
		rm "${LIBRARY_CACHE_FILE}.subfile"
	done
}

use.generate-cache.create-import() {
	local METADATA="$1"

	local FILENAME="$(echo "${METADATA}" | jq -r .LIBRARY_FILE)"
	local SCWRYPTSMODULE="$(echo "${METADATA}" | jq -r .scwryptsmodule)"
	local GROUP="$(echo "${METADATA}" | jq -r .SCWRYPTS_LIBRARY_GROUP)"
	local LIBRARY="$(echo "${METADATA}" | jq -r .SCWRYPTS_LIBRARY | sed 's|[/-]|_|g')"

	local IS_LOADED_VARIABLE="SCWRYPTS_LIBRARY_LOADED__${GROUP}__${LIBRARY}"

	echo "[[ \$${IS_LOADED_VARIABLE} =~ true ]] && return 0"
	echo "export scwryptsmodule=${SCWRYPTSMODULE}"
	sed "/^use\\s/aexport scwryptsmodule=${SCWRYPTSMODULE}" "${FILENAME}"
	echo "${IS_LOADED_VARIABLE}=true"
	echo "unset scwryptsmodule"
}
