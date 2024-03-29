SCWRYPTS_KUBECTL_CUSTOM_COMMAND_PARSE__meta() {
	USAGE__usage+=" meta"
	USAGE__args="
	- get     output value of meta variable
	- set     interactively configure value of meta variable
	- clear   clear current subsession variables

	(settings args)
	- show   output context for every command
	- hide   (default) hide output context for every command

	- strict   (default) require context *and* namespace to be set
	- loose    do not require context and namespace to be set
	"
	USAGE__options=''
	USAGE__description=$(SCWRYPTS_KUBECTL_CUSTOM_COMMAND_DESCRIPTION__meta)

	META_SUBARGS="
	- namespace
	- context
	"

	while [[ $# -gt 0 ]]
	do
		case $1 in
			-h | --help ) HELP=1 ;;

			set ) 
				USAGE__usage+=" set"
				USAGE__args="set (namespace|context)"
				USAGE__description="interactively set a namespace or context for '$SCWRYPTS_ENV'"
				case $2 in
					namespace | context ) USER_ARGS+=($1 $2 $3); [ $3 ] && shift 1 ;;
					-h | --help ) HELP=1 ;;
					'' )
						: \
							&& SCWRYPTS_KUBECTL_CUSTOM_COMMAND__meta set context \
							&& SCWRYPTS_KUBECTL_CUSTOM_COMMAND__meta set namespace \
							;
						return $?
						;;

					* ) ERROR "cannot set '$2'" ;;
				esac
				shift 1
				;;

			get )
				USAGE__usage+=" get"
				USAGE__args="get (namespace|context|all)"
				USAGE__description="output the current namespace or context for '$SCWRYPTS_ENV'"
				case $2 in
					namespace | context | all ) USER_ARGS+=($1 $2) ;;

					-h | --help ) HELP=1 ;;

					* ) ERROR "cannot get '$2'" ;;
				esac
				shift 1
				;;

			copy )
				USAGE__usage+=" copy"
				USAGE__args+="copy [0-9]"
				USAGE__description="copy current subsession ($SUBSESSION) to target subsession id"
				case $2 in
					[0-9] ) USER_ARGS+=($1 $2) ;;
					-h | --help ) HELP=1 ;;
					* ) ERROR "target session must be a number [0-9]" ;;
				esac
				shift 1
				;;

			clear | show | hide | strict | loose ) USER_ARGS+=($1) ;;

			* ) ERROR "no meta command '$1'"
		esac
		shift 1
	done
}

SCWRYPTS_KUBECTL_CUSTOM_COMMAND__meta() {
	case $1 in
		get )
			[[ $2 =~ ^all$ ]] && {
				local CONTEXT=$(REDIS get --prefix current:context | grep . || echo "\\033[1;31mnone set\\033[0m")
				local NAMESPACE=$(REDIS get --prefix current:namespace | grep . || echo "\\033[1;31mnone set\\033[0m")
				echo "
					environment : $SCWRYPTS_ENV
					context     : $CONTEXT
					namespace   : $NAMESPACE

					CLI settings
					  command context : $(_SCWRYPTS_KUBECTL_SETTINGS get context)
					      strict mode : $([[ $STRICT -eq 1 ]] && echo "on" || echo "\\033[1;31moff\\033[0m")
					" | sed 's/^	\+//' >&2
				return 0
			}

			REDIS get --prefix current:$2
			;;

		set )
			scwrypts -n --name set-$2 --type zsh --group kubectl -- $3 --subsession $SUBSESSION >/dev/null \
				&& SUCCESS "$2 set"
			;;

		copy )
			: \
				&& STATUS "copying $1 to $2" \
				&& scwrypts -n --name set-context --type zsh --group kubectl -- --subsession $2 $(k meta get context | grep . || echo 'reset') \
				&& scwrypts -n --name set-namespace --type zsh --group kubectl -- --subsession $2 $(k meta get namespace | grep . || echo 'reset') \
				&& SUCCESS "subsession $1 copied to $2" \
				;
			;;

		clear )
			scwrypts -n --name set-context --type zsh --group kubectl -- --subsession $SUBSESSION reset >/dev/null \
				&& SUCCESS "subsession $SUBSESSION reset to default"
			;;

		show )
			_SCWRYPTS_KUBECTL_SETTINGS set context show >/dev/null \
				&& SUCCESS "now showing full command context"
			;;

		hide )
			_SCWRYPTS_KUBECTL_SETTINGS set context hide >/dev/null \
				&& SUCCESS "now hiding command context"
			;;

		loose )
			_SCWRYPTS_KUBECTL_SETTINGS set strict 0 >/dev/null \
				&& WARNING "now running in 'loose' mode"
			;;

		strict )
			_SCWRYPTS_KUBECTL_SETTINGS set strict 1 >/dev/null \
				&& SUCCESS "now running in 'strict' mode"
			;;
	esac
}

SCWRYPTS_KUBECTL_CUSTOM_COMMAND_DESCRIPTION__meta() {
	[ $CLI ] || CLI='kubectl'
	echo "operations for $CLI session variables and other CLI settings"
}
