#
# configuration options for scwrypts
#

SCWRYPTS_SHORTCUT=' '         # CTRL + SPACE
SCWRYPTS_ENV_SHORTCUT=''     # CTRL + /
SCWRYPTS_BUILDER_SHORTCUT='' # CTRL + Y

#####################################################################

# true / false; include help information during environment edit
SCWRYPTS_ENVIRONMENT__SHOW_ENV_HELP=true

# basic / quiet; swaps the default environment editor mode
SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE=basic


# true / false; includes descriptive comments when using
#               scwrypts/template generators
SCWRYPTS_GENERATOR__SHOW_HELP=true

#####################################################################

# fully-qualified path to scwrypts groups / plugins '*.scwrypts.zsh'
SCWRYPTS_GROUP_LOADERS=()

# fully-qualified path to directories which should be searched for '*.scwrypts.zsh'
SCWRYPTS_GROUP_DIRS=(
	"${XDG_DATA_HOME:-${HOME}/.local/share}/scwrypts-plugins"
	/usr/share/scwrypts-plugins/
	"${__SCWRYPTS_ROOT}/plugins"
)
