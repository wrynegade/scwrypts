#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use system/vim

#####################################################################

VUNDLE__PLUGIN_DIR="${VIM_CONFIG_DIR}/bundle"
VUNDLE__BUILD_DEFINITIONS="$SCWRYPTS_CONFIG_PATH/vundle.zsh"

[ ! -f $VUNDLE__BUILD_DEFINITIONS ] && {
	{
		echo -e "#\n# Scwrypts Build Definitions\n#\n"
	} > $VUNDLE__BUILD_DEFINITIONS
}

VUNDLE__PLUGIN_LIST=$(ls $VUNDLE__PLUGIN_DIR | grep -v 'Vundle.vim' | grep -v 'build.zsh')
source $VUNDLE__BUILD_DEFINITIONS
for PLUGIN in $(echo $VUNDLE__PLUGIN_LIST)
do
	which VUNDLE__BUILD__$PLUGIN >/dev/null 2>/dev/null || {
		echo -e "\nVUNDLE__BUILD__$PLUGIN() {\n	# ... build steps from $HOME/.vim/$PLUGIN \n}" \
			>> $VUNDLE__BUILD_DEFINITIONS
		VUNDLE__BUILD__$PLUGIN() {}
	}
done

#####################################################################

VUNDLE__PLUGIN_INSTALL() {
	VIM +PluginInstall +qall \
		&& echo.success 'successfully installed Vundle.vim plugins' \
		|| utils.fail 1 'failed to install Vundle.vim plugins'
}

VUNDLE__REBUILD_PLUGINS() {
	local ERRORS=0

	local PLUGIN
	for PLUGIN in $(echo $VUNDLE__PLUGIN_LIST)
	do
		cd "$VUNDLE__PLUGIN_DIR/$PLUGIN"
		echo.status "building '$PLUGIN'"
		VUNDLE__BUILD__$PLUGIN \
			&& echo.success "finished building '$PLUGIN'" \
			|| echo.error "failed to build '$PLUGIN' (see above)" \
			;
	done

	return $ERRORS
}
