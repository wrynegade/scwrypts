[[ $__SCWRYPT -eq 1 ]] && return 0
#####################################################################

[ ! $SCWRYPTS_ROOT ] \
	&& SCWRYPTS_ROOT="$(cd $(dirname "${0:a:h}"); git rev-parse --show-toplevel)"

#####################################################################

DEFAULT_CONFIG="$SCWRYPTS_ROOT/zsh/lib/config.user.zsh"
source "$DEFAULT_CONFIG"

USER_CONFIG_OVERRIDES="$SCWRYPTS_CONFIG_PATH/config.zsh"
[ ! -f "$USER_CONFIG_OVERRIDES" ] && {
	mkdir -p $(dirname "$USER_CONFIG_OVERRIDES")
	cp "$DEFAULT_CONFIG" "$USER_CONFIG_OVERRIDES"
}
source "$USER_CONFIG_OVERRIDES"

[ ! -d $SCWRYPTS_CONFIG_PATH ] && mkdir -p $SCWRYPTS_CONFIG_PATH
[ ! -d $SCWRYPTS_DATA_PATH   ] && mkdir -p $SCWRYPTS_DATA_PATH
[ ! -d $SCWRYPTS_ENV_PATH    ] && mkdir -p $SCWRYPTS_ENV_PATH
[ ! -d $SCWRYPTS_LOG_PATH    ] && mkdir -p $SCWRYPTS_LOG_PATH
[ ! -d $SCWRYPTS_OUTPUT_PATH ] && mkdir -p $SCWRYPTS_OUTPUT_PATH

export \
	SCWRYPTS_GROUPS \
	SCWRYPTS_CONFIG_PATH \
	SCWRYPTS_DATA_PATH \
	SCWRYPTS_SHORTCUT \
	SCWRYPTS_ENV_SHORTCUT \
	SCWRYPTS_LOG_PATH \
	SCWRYPTS_OUTPUT_PATH \
	;

SCWRYPTS_GROUPS+=(scwrypts) # 'scwrypts' group is required!
SCWRYPTS_GROUPS=($(echo $SCWRYPTS_GROUPS | sed 's/\s\+/\n/g' | sort -u))

source "$SCWRYPTS_ROOT/zsh/lib/config.group.zsh" \
	|| FAIL 69 'failed to set up scwrypts group; aborting'

#####################################################################

[[ $SCWRYPTS_PLUGIN_ENABLED__kubectl -eq 1 ]] && {
	source "$SCWRYPTS_ROOT/plugins/kubectl/kubectl.scwrypts.zsh"
}

#####################################################################
[ $NO_EXPORT_CONFIG ] || __SCWRYPT=1 # arbitrary; indicates currently inside a scwrypt
true
