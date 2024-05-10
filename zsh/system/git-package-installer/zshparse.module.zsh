#####################################################################

DEPENDENCIES+=(git)

#####################################################################

${scwryptsmodule}() {
	# local GIT_REPOSITORY_URL LOCAL_NAME INSTALLATION_BASE_PATH
	# local UPDATE=false MAKE_CLEAN=false
	# local PASSTHROUGH_ARGS=()
	local PARSED=0

	case $1 in
		( -t | --target-url )
			PARSED=2
			GIT_REPOSITORY_URL="$2"
			# PASSTHROUGH_ARGS+=() included in .validate()
			;;

		( -n | --local-name )
			PARSED=2
			LOCAL_NAME="$2"
			# PASSTHROUGH_ARGS+=() included in .validate()
			;;

		( -u | --update     ) PARSED=1; PASSTHROUGH_ARGS+=(-u); UPDATE=true     ;;
		( -c | --make-clean ) PARSED=1; PASSTHROUGH_ARGS+=(-c); MAKE_CLEAN=true ;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.usage() {
	USAGE__options+='
		-t, --target-url <string>   target git repository address for build source
		-n, --local-name <string>   (optional) override the default git-clone name for local directory

		-u, --update       if package exists, update using current branch
		-c, --make-clean   when using a "make" target, invoke "make clean" before (re)build/install
	'
}

${scwryptsmodule}.validate() {
	INSTALLATION_BASE_PATH="${XDG_DATA_HOME:-${HOME}/.local/share}/git-packages-source"
	mkdir -p -- "${INSTALLATION_BASE_PATH}"

	[ ! ${GIT_REPOSITORY_URL} ] && [ ! ${LOCAL_NAME} ] && {
		UPDATE=true
		LOCAL_NAME=$(\
			cd "${INSTALLATION_BASE_PATH}"; \
			find . -mindepth 1 -maxdepth 1 -type d \
				| sed 's|^\./||' \
				| utils.fzf 'select a package to update' \
			)

		[ ${LOCAL_NAME} ] \
			|| echo.error '--target-url or --local-name required' \
			|| return \
			;
	}

	[ ! "${GIT_REPOSITORY_URL}" ] && [ "${LOCAL_NAME}" ] && [ -d "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}/.git" ] && {
		GIT_REPOSITORY_URL="$(\
			git -C "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}" remote -v \
				| grep ^origin.*(fetch)$ \
				| awk '{print $2;}' \
				| head -n 1 \
		)"
	}

	[ "${GIT_REPOSITORY_URL}" ] && [ ! "${LOCAL_NAME}" ] && {
		LOCAL_NAME="$(basename -- "${GIT_REPOSITORY_URL}" | sed 's/\.git$//')"
	}

	[ "${GIT_REPOSITORY_URL}" ] && [ "${LOCAL_NAME}" ] \
		|| echo.error "couldn't determine URL automatically\n('${LOCAL_NAME}' must be installed at '${INSTALLATION_BASE_PATH}/${LOCAL_NAME}')"

	PASSTHROUGH_ARGS+=(-t "${GIT_REPOSITORY_URL}" -n "${LOCAL_NAME}")
}

#####################################################################
