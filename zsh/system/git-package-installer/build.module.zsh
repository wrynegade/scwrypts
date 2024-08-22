#####################################################################

use system/git-package-installer/zshparse

#####################################################################

${scwryptsmodule}() {
	local \
		GIT_REPOSITORY_URL LOCAL_NAME INSTALLATION_BASE_PATH \
		UPDATE=false MAKE_CLEAN=false \
		PASSTHROUGH_ARGS=() \
		PARSERS=(
			system.git-package-installer.zshparse
			)
	
	eval "$ZSHPARSEARGS"

	##########################################
	
	[ -d "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}" ] || {
		system.git-package-installer.clone ${PASSTHROUGH_ARGS[@]} \
			|| return 1
	}

	local INSTALLER
	[ -f "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}/Makefile" ] && INSTALLER=make
	[ -f "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}/PKGBUILD" ] && INSTALLER=makepkg

	case ${INSTALLER} in
		( make | makepkg )
			echo.status "installing '${LOCAL_NAME}'"
			system.git-package-installer.build.${INSTALLER}
			;;
		( * )
			echo.warning  'could not detect supported installation method'
			echo.reminder "complete manual installation here:\n${INSTALLATION_BASE_PATH}/${LOCAL_NAME}"
			;;
	esac
}

#####################################################################

${scwryptsmodule}.make() {
	utils.dependencies.check make || return 1
	(
		cd "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}"
		[[ ${MAKE_CLEAN} =~ true ]] && make clean

		: \
			&& make \
			&& GETSUDO \
			&& sudo make install \
			&& echo.success "succesfully installed '${LOCAL_NAME}'" \
			|| echo.error   "failed to install '${LOCAL_NAME}' (see above)" \
		;
	)
}

${scwryptsmodule}.makepkg() {
	utils.dependencies.check makepkg || return 1
	(
		cd "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}"

		yes | makepkg -si \
			&& echo.success "succesfully installed '${LOCAL_NAME}'" \
			|| echo.error   "failed to install '${LOCAL_NAME}' (see above)" \
			;
	)
}
