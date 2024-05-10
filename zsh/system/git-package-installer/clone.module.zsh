#####################################################################

use system/git-package-installer/zshparse

DEPENDENCIES+=(git)

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

	[ -d "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}/.git" ] \
		&& echo.success "already cloned '${LOCAL_NAME}'" \
		&& return 0 \
		;

	##########################################

	git clone "${GIT_REPOSITORY_URL}" "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}" \
		&& echo.success "successfully cloned '${LOCAL_NAME}'\ninstall dir : ${INSTALLATION_BASE_PATH}/${LOCAL_NAME}" \
		|| echo.error   "failed to clone '${LOCAL_NAME}'" \
		;
}
