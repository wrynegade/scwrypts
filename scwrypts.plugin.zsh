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
	SCWRYPT_SELECTION=$(scwrypts --list | fzf --ansi --prompt 'select a script : ' --header-lines 1)
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

# badass(/terrifying?) zsh autocompletion
command -v compdef &>/dev/null && {
	_scwrypts() {
		echo $words | grep -q "\s--\s" && _arguments && return 0
		eval "_arguments $(
			{
			HELP=$(scwrypts --help 2>&1 | sed -n 's/^\s\+\(-.*   .\)/\1/p' | sed 's/[[]/(/g; s/[]]/)/g')
			echo $HELP \
				| sed 's/^\(\(-[^-\s]\),*\s*\|\)\(\(--[-a-z0-9A-Z\]*\)\s\(<\([^>]*\)>\|\)\|\)\s\+\(.*\)/\2[\7]:\6:->\2/' \
				| grep -v '^[[]' \
				;

			echo $HELP \
				| sed 's/^\(\(-[^-\s]\),*\s*\|\)\(\(--[-a-z0-9A-Z\]*\)\s\(<\([^>]*\)>\|\)\|\)\s\+\(.*\)/\4[\7]:\6:->\4/' \
				| grep -v '^[[]' \
				;

			echo ":pattern:->pattern"
			echo ":pattern:->pattern"
			echo ":pattern:->pattern"
			echo ":pattern:->pattern"
			echo ":pattern:->pattern"

			} | sed 's/::->.*$//g' | sed "s/\\(^\\|$\\)/'/g" | tr '\n' ' '
		)"

		local _group=''
		echo $words | grep -q ' -g [^\s]' \
			&& _group=$(echo $words | sed 's/.*-g \([^ 	]\+\)\s*.*/\1/')
		echo $words | grep -q ' --group .' \
			&& _group=$(echo $words | sed 's/.*--group \([^ 	]\+\)\s*.*/\1/')

		local _type=''
		echo $words | grep -q ' -t [^\s]' \
			&& _type=$(echo $words | sed 's/.*-t \([^ 	]\+\)\s*.*/\1/')
		echo $words | grep -q ' --type .' \
			&& _type=$(echo $words | sed 's/.*--type \([^ 	]\+\)\s*.*/\1/')

		local _name=''
		echo $words | grep -q ' -m [^\s]' \
			&& _name=$(echo $words | sed 's/.*-m \([^ 	]\+\)\s*.*/\1/')
		echo $words | grep -q ' --name .' \
			&& _name=$(echo $words | sed 's/.*--name \([^ 	]\+\)\s*.*/\1/')

		local _pattern _patterns=()
		[ ! $_name ] \
			&& _patterns=($(echo "${words[@]:1}" | sed 's/\s\+/\n/g' | grep -v '^-'))

		_get_remaining_scwrypts() {
			[ $_name  ] || local  _name='[^ 	]\+'
			[ $_type  ] || local  _type='[^ 	]\+'
			[ $_group ] || local _group='[^ 	]\+'

			local remaining=$(\
				scwrypts --list \
					| sed "1d; s,\x1B\[[0-9;]*[a-zA-Z],,g" \
					| grep "^$_name\s" \
					| grep "\s$_group$" \
					| grep "\s$_type\s" \
				)

			for _pattern in ${_patterns[@]}
			do
				remaining=$(echo "$remaining" | grep "$_pattern")
			done

			echo "$remaining"
		}

		case $state in
			( -m | --name )
				compadd $(_get_remaining_scwrypts | awk '{print $1;}' | sort -u)
				;;

			( -t | --type )
				compadd $(_get_remaining_scwrypts | awk '{print $2;}' | sort -u)
				;;

			( -g | --group )
				[[ $_name$_type$_group =~ ^$ ]] \
					&& compadd $(scwrypts --list-groups) \
					|| compadd $(_get_remaining_scwrypts | awk '{print $3;}' | sort -u) \
				;;

			( -e | --env )
				compadd $(scwrypts --list-envs)
				;;

			( -v | --log-level )
				local _help="$(\
					scwrypts --help 2>&1 \
						| sed -n '/-v, --log-level/,/^$/p' \
						| sed -n 's/\s\+\([0-9]\) : \(.*\)/\1 -- \2/p' \
				)"

				eval "local _descriptions=($(echo "$_help" | sed "s/\\(^\|$\\)/'/g"))"
				local _values=($(echo "$_help" | sed 's/ --.*//'))
				compadd -d _descriptions -a _values
				;;

			( -o | --output )
				compadd pretty json
				;;

			( pattern )
				[[ $_name =~ ^$ ]] && {
					local _remaining_scwrypts="$(_get_remaining_scwrypts)"
					# stop providing suggestions if your pattern is sufficient
					[[ $(echo $_remaining_scwrypts | wc -l) -le 1 ]] && return 0

					local _remaining_patterns="$(echo "$_remaining_scwrypts" | sed 's/\s\+/\n/g; s|/|\n|g; s/-/\n/g;' | sort -u)"

					for _pattern in ${_patterns[@]}
					do
						_remaining_patterns="$(echo "$_remaining_patterns" | grep -v "^$_pattern$")"
					done
					compadd $(echo $_remaining_patterns)
				}
				;;

			( * ) ;;
		esac
	}
	compdef _scwrypts scwrypts
}

__SCWRYPTS_PLUGIN_LOADED=true
