source ${0:a:h}/zsh/common.zsh
#####################################################################
[ ! $SCWRYPTS_SHORTCUT ] && {
	export SCWRYPTS_SHORTCUT=' ' # CTRL + SPACE
}

__SCWRYPTS() {

	local SCRIPT=$(__GET_AVAILABLE_SCRIPTS | __FZF 'select a script')
	zle clear-command-line
	[ ! $SCRIPT ] && { zle accept-line; return 0; }

	which scwrypts >/dev/null 2>&1\
		&& RBUFFER="scwrypts" || RBUFFER="$SCWRYPTS_ROOT/scwrypts"

	RBUFFER+=" $SCRIPT"
	zle accept-line
}

zle -N scwrypts __SCWRYPTS
bindkey $SCWRYPTS_SHORTCUT scwrypts

#####################################################################
[ ! $SCWRYPTS_ENV_SHORTCUT ] && {
	export SCWRYPTS_ENV_SHORTCUT='' # CTRL + /
}

__SCWRYPTS_ENV() {
	local RESET='reset'
	local SELECTED=$(\
		{ [ $SCWRYPTS_ENV ] && echo $RESET; __GET_ENV_NAMES; } \
			| __FZF 'select an environment' \
	)

	zle clear-command-line
	[ $SELECTED ] && {
		[[ $SELECTED =~ ^$RESET$ ]] \
			&& RBUFFER='unset SCWRYPTS_ENV' \
			|| RBUFFER="export SCWRYPTS_ENV=$SELECTED"
	}
	zle accept-line
}

zle -N scwrypts-setenv __SCWRYPTS_ENV
bindkey $SCWRYPTS_ENV_SHORTCUT scwrypts-setenv
