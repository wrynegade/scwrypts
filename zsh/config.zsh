#####################################################################
### preflight config validation #####################################
#####################################################################

[[ ${__SCWRYPT} -eq 1 ]] && return 0  # avoid config reload if already active

# Apparently MacOS puts ALL of the homebrew stuff inside of a top level git repository
# with bizarre git ignores; so:
#  - USE the git root if it's a manual install...
#  - UNLESS that git root is just the $(brew --prefix)
__SCWRYPTS_ROOT="$(cd -- "${0:a:h}"; git rev-parse --show-toplevel 2>/dev/null | grep -v "^$(brew --prefix 2>/dev/null)$")"

[ ${__SCWRYPTS_ROOT} ] && [ -d "${__SCWRYPTS_ROOT}" ] \
	|| __SCWRYPTS_ROOT="$(echo "${0:a:h}" | sed -n 's|\(share/scwrypts\).*$|\1|p')"

[ ${__SCWRYPTS_ROOT} ] && [ -d "${__SCWRYPTS_ROOT}" ] || {
	echo "cannot determine scwrypts root path for current installation; aborting"
	exit 1
}

[ -f "${__SCWRYPTS_ROOT}/MANAGED_BY" ] \
	&& readonly SCWRYPTS_INSTALLATION_TYPE=$(cat "${__SCWRYPTS_ROOT}/MANAGED_BY") \
	|| readonly SCWRYPTS_INSTALLATION_TYPE=manual \
	;

#####################################################################
### scwrypts global configuration ###################################
#####################################################################

readonly SCWRYPTS_CONFIG_PATH="${XDG_CONFIG_HOME:-${HOME}/.config}/scwrypts"
readonly SCWRYPTS_ENV_PATH="${SCWRYPTS_CONFIG_PATH}/environments"

readonly SCWRYPTS_DATA_PATH="${XDG_DATA_HOME:-${HOME}/.local/share}/scwrypts"

readonly SCWRYPTS_STATE_PATH="${XDG_STATE_HOME:-${HOME}/.local/state}/scwrypts"
readonly SCWRYPTS_LOG_PATH="${SCWRYPTS_STATE_PATH}/logs"

[ -d /tmp ] \
	&& readonly SCWRYPTS_TEMP_PATH="/tmp/scwrypts/${SCWRYPTS_RUNTIME_ID}" \
	|| readonly SCWRYPTS_TEMP_PATH="${XDG_RUNTIME_DIR:-/run/user/${UID}}/scwrypts/${SCWRYPTS_RUNTIME_ID}" \
	;

mkdir -p \
	"${SCWRYPTS_ENV_PATH}" \
	"${SCWRYPTS_LOG_PATH}" \
	"${SCWRYPTS_TEMP_PATH}" \
	;

DEFAULT_CONFIG="${__SCWRYPTS_ROOT}/zsh/config.user.zsh"
source "${DEFAULT_CONFIG}"

USER_CONFIG_OVERRIDES="${SCWRYPTS_CONFIG_PATH}/config.zsh"

[ ! -f "${USER_CONFIG_OVERRIDES}" ] && {
	mkdir -p $(dirname "${USER_CONFIG_OVERRIDES}")
	cp "${DEFAULT_CONFIG}" "${USER_CONFIG_OVERRIDES}"
}

source "${USER_CONFIG_OVERRIDES}"
source "${0:a:h}/config.global.zsh"

#####################################################################
### load groups and plugins #########################################
#####################################################################

SCWRYPTS_GROUPS=()

command -v echo.warning &>/dev/null || WARNING() { echo "echo.warning : $@" >&2; }
command -v echo.error   &>/dev/null || ERROR()   { echo "echo.error   : $@" >&2; return 1; }
command -v FAIL    &>/dev/null || FAIL()    { echo.error "${@:2}"; exit $1; }

__SCWRYPTS_GROUP_LOADERS=(
	"${__SCWRYPTS_ROOT}/scwrypts.scwrypts.zsh"
)

[ "${GITHUB_WORKSPACE}" ] && [ ! "${SCWRYPTS_GITHUB_NO_AUTOLOAD}" ] && {
	SCWRYPTS_GROUP_DIRS+=("${GITHUB_WORKSPACE}")
}

for __SCWRYPTS_GROUP_DIR in ${SCWRYPTS_GROUP_DIRS[@]}
do
	[ -d "${__SCWRYPTS_GROUP_DIR}" ] || continue
	for __SCWRYPTS_GROUP_LOADER in $(find "${__SCWRYPTS_GROUP_DIR}" -type f -name \*scwrypts.zsh)
	do
		__SCWRYPTS_GROUP_LOADERS+=("${__SCWRYPTS_GROUP_LOADER}")
	done
done

scwrypts.config.group() {
	local GROUP_NAME="$1"
	local CONFIG_KEY="$2"

	[ "$GROUP_NAME" ] && [ "$CONFIG_KEY" ] \
		|| return 1

	echo ${(P)$(echo SCWRYPTS_GROUP_CONFIGURATION__${GROUP_NAME}__${CONFIG_KEY})}
}

for __SCWRYPTS_GROUP_LOADER in ${__SCWRYPTS_GROUP_LOADERS}
do
	__SCWRYPTS_GROUP_LOADER_REALPATH="$(readlink -f -- "${__SCWRYPTS_GROUP_LOADER}")"

	[ -f "${__SCWRYPTS_GROUP_LOADER_REALPATH}" ] || {
		echo.warning "error loading group '${__SCWRYPTS_GROUP_LOADER}': cannot read file"
		continue
	}

	__SCWRYPTS_GROUP_NAME="$(\
		basename -- "${__SCWRYPTS_GROUP_LOADER_REALPATH}" \
			| sed -n 's/^\([a-z][a-z0-9_]*[a-z0-9]\).scwrypts.zsh$/\1/p' \
	)"

	[ "$__SCWRYPTS_GROUP_NAME" ] || {
		echo.warning "unable to load group '${__SCWRYPTS_GROUP_LOADER_REALPATH}': invalid group name" >&2
		continue
	}

	[[ $(scwrypts.config.group "$__SCWRYPTS_GROUP_NAME" loaded) =~ true ]] && {
		echo.warning "unable to load group '${__SCWRYPTS_GROUP_NAME}': duplicate name"
		continue
	}

	scwryptsgroup="SCWRYPTS_GROUP_CONFIGURATION__${__SCWRYPTS_GROUP_NAME}"
	scwryptsgrouproot="$(dirname -- "${__SCWRYPTS_GROUP_LOADER_REALPATH}")"

	: \
		&& readonly ${scwryptsgroup}__root="${scwryptsgrouproot}" \
		&& source "${__SCWRYPTS_GROUP_LOADER_REALPATH}" \
		&& SCWRYPTS_GROUPS+=(${__SCWRYPTS_GROUP_NAME}) \
		&& readonly ${scwryptsgroup}__loaded=true \
		|| echo.warning "error encountered when loading group '${__SCWRYPTS_GROUP_NAME}'" \
		;
done

[[ ${SCWRYPTS_GROUPS[1]} =~ ^scwrypts$ ]] \
	|| FAIL 69 "encountered error when loading essential group 'scwrypts'; aborting"

#####################################################################
### cleanup #########################################################
#####################################################################

unset __SCWRYPTS_ROOT  # you should now use '$(scwrypts.config.group scwrypts root)'

unset \
	__SCWRYPTS_GROUP_LOADER __SCWRYPTS_GROUP_LOADERS __SCWRYPTS_GROUP_LOADER_REALPATH \
	__SCWRYPTS_GROUP_DIR SCWRYPTS_GROUP_DIRS \
	__SCWRYPTS_GROUP_NAME \
	scwryptsgroup scwryptsgrouproot \
	;

__SCWRYPT=1  # arbitrary; indicates currently inside a scwrypt
