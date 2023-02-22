#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

#####################################################################

DEFAULT_CONFIG="${0:a:h}/default.conf.zsh"

SAFE_SYMLINKS=1

# in case dotfiles.zsh is sourced; allows users to provide initial config
[ ! $CONFIG__USER_SETTINGS ] \
	&& CONFIG__USER_SETTINGS="$SCWRYPTS_CONFIG_PATH/dotfiles.zsh"

[ ! -f "$CONFIG__USER_SETTINGS" ] && cp "$DEFAULT_CONFIG" "$CONFIG__USER_SETTINGS"

source "$CONFIG__USER_SETTINGS"
