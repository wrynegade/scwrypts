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

	[[ $UPDATE =~ false ]] \
		&& echo.success "no update requested" \
		&& return 0 \
		;

	##########################################

	local TARGET_BRANCH=$(git -C "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}" rev-parse --abbrev-ref HEAD)

	git -C "${INSTALLATION_BASE_PATH}/${LOCAL_NAME}" pull origin ${TARGET_BRANCH} \
		&& echo.success "successfully updated '${LOCAL_NAME}'" \
		|| echo.error   "failed to update '${LOCAL_NAME}'" \
		;
}
