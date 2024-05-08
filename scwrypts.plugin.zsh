#
# typically you do not need to reload this plugin in a single session;
# if for some reason you do, you can run the following command and
# source this file again
#
# unset __SCWRYPTS_PLUGIN_LOADED
#
[[ $__SCWRYPTS_PLUGIN_LOADED =~ true ]] && return 0

#####################################################################

: \
	&& command -v scwrypts &>/dev/null \
	&& eval "$(scwrypts --config)" \
	|| {
		echo 'scwrypts must be in PATH and properly configured; skipping zsh plugin setup' >&2
		return 0
	}

__SCWRYPTS_PARSE() {
	SCWRYPT_SELECTION=$(scwrypts --list | fzf --prompt 'select a script : ' --header-lines 1)
	LBUFFER= RBUFFER=
	[ $SCWRYPT_SELECTION ] || return 1

	NAME=$(echo "$SCWRYPT_SELECTION" | awk '{print $1;}')
	TYPE=$(echo "$SCWRYPT_SELECTION" | awk '{print $2;}')
	GROUP=$(echo "$SCWRYPT_SELECTION" | awk '{print $3;}')

	[ $NAME ] && [ $TYPE ] && [ $GROUP ]
}

#####################################################################

[ $SCWRYPTS_SHORTCUT ] && {
	SCWRYPTS__ZSH_PLUGIN() {
		local SCWRYPT_SELECTION NAME TYPE GROUP
		__SCWRYPTS_PARSE || { zle accept-line; return 0; }

		RBUFFER="scwrypts --name $NAME --type $TYPE --group $GROUP"
		zle accept-line
	}

	zle -N scwrypts SCWRYPTS__ZSH_PLUGIN
	bindkey $SCWRYPTS_SHORTCUT scwrypts
	unset SCWRYPTS_SHORTCUT
}

#####################################################################

[ $SCWRYPTS_BUILDER_SHORTCUT ] && {
	SCWRYPTS__ZSH_BUILDER_PLUGIN() {
		local SCWRYPT_SELECTION NAME TYPE GROUP
		__SCWRYPTS_PARSE || { echo >&2; zle accept-line; return 0; }
		echo $SCWRYPT_SELECTION >&2

		scwrypts -n --name $NAME --group $GROUP --type $TYPE -- --help >&2 || {
			zle accept-line
			return 0
		}
		echo

		zle reset-prompt
		LBUFFER="scwrypts --name $NAME --type $TYPE --group $GROUP -- "
	}

	zle -N scwrypts-builder SCWRYPTS__ZSH_BUILDER_PLUGIN
	bindkey $SCWRYPTS_BUILDER_SHORTCUT scwrypts-builder
	unset SCWRYPTS_BUILDER_SHORTCUT
}

#####################################################################

[ $SCWRYPTS_ENV_SHORTCUT ] && {
	SCWRYPTS__ZSH_PLUGIN_ENV() {
		local RESET='reset'
		local SELECTED=$(\
			{ [ $SCWRYPTS_ENV ] && echo $RESET; scwrypts --list-envs; } \
				| fzf --prompt 'select an environment : ' \
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
	unset SCWRYPTS_ENV_SHORTCUT
}

#####################################################################

__SCWRYPTS_PLUGIN_LOADED=true
