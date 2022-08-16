_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

VUNDLE_PLUGIN_DIR="$HOME/.vim/bundle"
VUNDLE_BUILD_DEFINITIONS="$VUNDLE_PLUGIN_DIR/build.zsh"

[ ! -f $VUNDLE_BUILD_DEFINITIONS ] && {
	{
		echo -e "#\n# Scwrypts Build Definitions\n#\n"
	} > $VUNDLE_BUILD_DEFINITIONS
}

VUNDLE_PLUGIN_LIST=$(ls $VUNDLE_PLUGIN_DIR | grep -v 'Vundle.vim' | grep -v 'build.zsh')
source $VUNDLE_BUILD_DEFINITIONS
for PLUGIN in $(echo $VUNDLE_PLUGIN_LIST)
do
	typeset -f VUNDLE_BUILD__$PLUGIN >/dev/null 2>/dev/null || {
		echo -e "\nVUNDLE_BUILD__$PLUGIN() {\n	# ... build steps from $HOME/.vim/$PLUGIN \n}" \
			>> $VUNDLE_BUILD_DEFINITIONS
		VUNDLE_BUILD__$PLUGIN() {}
	}
done

#####################################################################

VUNDLE_PLUGIN_INSTALL() {
	_VIM +PluginInstall +qall \
		&& __SUCCESS 'successfully installed Vundle.vim plugins' \
		|| __FAIL 1 'failed to install Vundle.vim plugins'
}

VUNDLE_REBUILD_PLUGINS() {
	local ERRORS=0

	local PLUGIN
	for PLUGIN in $(echo $VUNDLE_PLUGIN_LIST)
	do
		cd "$VUNDLE_PLUGIN_DIR/$PLUGIN"
		__STATUS "building '$PLUGIN'"
		VUNDLE_BUILD__$PLUGIN \
			&& __SUCCESS "finished building '$PLUGIN'" \
			|| __ERROR "failed to build '$PLUGIN' (see above)" \
			;
	done

	return $ERRORS
}
