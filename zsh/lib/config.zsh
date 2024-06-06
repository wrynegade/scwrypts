[[ $__SCWRYPT -eq 1 ]] && return 0  # avoid config reload if already active
#####################################################################

# Apparently MacOS puts ALL of the homebrew stuff inside of a top level git repository
# with bizarre git ignores; so:
#  - USE the git root if it's a manual install...
#  - UNLESS that git root is just the $(brew --prefix)
SCWRYPTS_ROOT="$(cd -- ${0:a:h}; git rev-parse --show-toplevel 2>/dev/null | grep -v "^$(brew --prefix 2>/dev/null)$")"

[ $SCWRYPTS_ROOT ] && [ -d "$SCWRYPTS_ROOT" ] \
	|| SCWRYPTS_ROOT="$(echo "${0:a:h}" | sed -n 's|\(share/scwrypts\).*$|\1|p')"

[ $SCWRYPTS_ROOT ] && [ -d "$SCWRYPTS_ROOT" ] || {
	echo "cannot determine scwrypts root path for current installation; aborting"
	exit 1
}

export SCWRYPTS_ROOT__scwrypts="$SCWRYPTS_ROOT"

[ -f "$SCWRYPTS_ROOT__scwrypts/MANAGED_BY" ] \
	&& export SCWRYPTS_INSTALLATION_TYPE=$(cat "$SCWRYPTS_ROOT__scwrypts/MANAGED_BY") \
	|| export SCWRYPTS_INSTALLATION_TYPE=manual \
	;


#####################################################################

DEFAULT_CONFIG="$SCWRYPTS_ROOT__scwrypts/zsh/lib/config.user.zsh"
source "$DEFAULT_CONFIG"

USER_CONFIG_OVERRIDES="$SCWRYPTS_CONFIG_PATH/config.zsh"
[ ! -f "$USER_CONFIG_OVERRIDES" ] && {
	mkdir -p $(dirname "$USER_CONFIG_OVERRIDES")
	cp "$DEFAULT_CONFIG" "$USER_CONFIG_OVERRIDES"
}
source "$USER_CONFIG_OVERRIDES"

SCWRYPTS_TEMP_PATH="$SCWRYPTS_TEMP_PATH/$SCWRYPTS_RUNTIME_ID"

mkdir -p \
	"$SCWRYPTS_CONFIG_PATH" \
	"$SCWRYPTS_DATA_PATH" \
	"$SCWRYPTS_TEMP_PATH" \
	"$SCWRYPTS_ENV_PATH" \
	"$SCWRYPTS_LOG_PATH" \
	"$SCWRYPTS_OUTPUT_PATH" \
	;

source "$SCWRYPTS_ROOT/scwrypts.scwrypts.zsh" \
	|| FAIL 69 'failed to set up scwrypts group; aborting'


#####################################################################

for plugin in $(ls $SCWRYPTS_ROOT__scwrypts/plugins)
do
	[[ $(eval 'echo $SCWRYPTS_PLUGIN_ENABLED__'$plugin) -eq 1 ]] && {
		source "$SCWRYPTS_ROOT/plugins/$plugin/$plugin.scwrypts.zsh"
	}
done

#####################################################################

for GROUP_LOADER in $(env | sed -n 's/^SCWRYPTS_GROUP_LOADER__[a-z_]\+=//p')
do
	[ -f "$GROUP_LOADER" ] && source "$GROUP_LOADER"
done

: \
	&& [ ! "$SCWRYPTS_AUTODETECT_GROUP_BASEDIR" ] \
	&& [ $GITHUB_WORKSPACE ] \
	&& [ ! $SCWRYPTS_GITHUB_NO_AUTOLOAD ] \
	&& SCWRYPTS_AUTODETECT_GROUP_BASEDIR="$GITHUB_WORKSPACE" \
	;

[ "$SCWRYPTS_AUTODETECT_GROUP_BASEDIR" ] && [ -d "$SCWRYPTS_AUTODETECT_GROUP_BASEDIR" ] && {
	for GROUP_LOADER in $(find "$SCWRYPTS_AUTODETECT_GROUP_BASEDIR" -type f -name \*scwrypts.zsh)
	do
		[ -f "$GROUP_LOADER" ] && source "$GROUP_LOADER"
	done
}

#####################################################################
__SCWRYPT=1  # arbitrary; indicates currently inside a scwrypt
