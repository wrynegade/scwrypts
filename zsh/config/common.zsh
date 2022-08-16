_DEPENDENCIES+=()
_REQUIRED_ENV+=()
DEFAULT_CONFIG="${0:a:h}/default.conf.zsh"
source ${0:a:h}/../common.zsh
#####################################################################

SAFE_SYMLINKS=1

# in case config.dotfile.zsh is sourced... allow user to provide initial config ;)
[ ! $CONFIG__USER_SETTINGS ] \
	&& CONFIG__USER_SETTINGS="$SCWRYPTS_CONFIG_PATH/config.dotfile.zsh"
[ ! -f "$CONFIG__USER_SETTINGS" ] && cp "$DEFAULT_CONFIG" "$CONFIG__USER_SETTINGS"
source $CONFIG__USER_SETTINGS
