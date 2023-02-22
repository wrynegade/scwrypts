NO_EXPORT_CONFIG=1 source "${0:a:h}/zsh/lib/import.driver.zsh" || return 42

#####################################################################
SCWRYPTS__ZSH_PLUGIN() {
	local SCWRYPT_SELECTION=$(SCWRYPTS__GET_AVAILABLE_SCWRYPTS | FZF 'select a script' --header-lines 1)
	local NAME
	local TYPE
	local GROUP
	zle clear-command-line
	[ ! $SCWRYPT_SELECTION ] && { zle accept-line; return 0; }

	SCWRYPTS__SEPARATE_SCWRYPT_SELECTION $SCWRYPT_SELECTION

	which scwrypts >/dev/null 2>&1\
		&& RBUFFER="scwrypts" || RBUFFER="$SCWRYPTS_ROOT/scwrypts"

	RBUFFER+=" --name $NAME --group $GROUP --type $TYPE"
	zle accept-line
}

zle -N scwrypts SCWRYPTS__ZSH_PLUGIN
bindkey $SCWRYPTS_SHORTCUT scwrypts

#####################################################################
SCWRYPTS__ZSH_PLUGIN_ENV() {
	local RESET='reset'
	local SELECTED=$(\
		{ [ $SCWRYPTS_ENV ] && echo $RESET; SCWRYPTS__GET_ENV_NAMES; } \
			| FZF 'select an environment' \
	)

	zle clear-command-line
	[ $SELECTED ] && {
		[[ $SELECTED =~ ^$RESET$ ]] \
			&& RBUFFER='unset SCWRYPTS_ENV' \
			|| RBUFFER="export SCWRYPTS_ENV=$SELECTED"
	}
	zle accept-line
}

zle -N scwrypts-setenv SCWRYPTS__ZSH_PLUGIN_ENV
bindkey $SCWRYPTS_ENV_SHORTCUT scwrypts-setenv
