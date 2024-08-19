[[ $SCWRYPTS_KUBECTL_DRIVER_READY -eq 1 ]] && return 0

unalias k h f >/dev/null 2>&1
k() { _SCWRYPTS_KUBECTL_DRIVER kubectl $@; }
h() { _SCWRYPTS_KUBECTL_DRIVER helm $@; }
f() { _SCWRYPTS_KUBECTL_DRIVER flux $@; }

_SCWRYPTS_KUBECTL_DRIVER() {
	[ ! $SCWRYPTS_ENV ] && {
		echo.error "must set SCWRYPTS_ENV in order to use '$(echo $CLI | head -c1)'"
		return 1
	}

	which REDIS >/dev/null 2>&1 \
		|| eval "$(scwrypts -n --name meta/get-static-redis-definition --type zsh --group kubectl)"

	local CLI="$1"; shift 1

	local SCWRYPTS_GROUP CUSTOM_COMMANDS=(meta)
	for SCWRYPTS_GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		CUSTOM_COMMANDS+=($(eval echo '$SCWRYPTS_KUBECTL_CUSTOM_COMMANDS__'$SCWRYPTS_GROUP))
	done

	##########################################

	local USAGE="
		usage: - [...args...] [...options...] -- [...$CLI options...]

		args: -

		options: -
		  --subsession [0-9]   use indicated subsession (use for script clarity instead of positional arg)

		  -h, --help      display this help dialogue
		  -v, --verbose   output debugging information

		description: -
	"

	local USAGE__usage=$(echo $CLI | head -c1) 

	local USAGE__args="$(
		{
			echo "\\033[0;32m[0-9]\\033[0m^if the first argument is a number 0-9, uses or creates a subsession (default 0)"
			echo " ^ "
			for C in ${CUSTOM_COMMANDS[@]}
			do
				echo "\\033[0;32m$C\\033[0m^$(SCWRYPTS_KUBECTL_CUSTOM_COMMAND_DESCRIPTION__$C 2>/dev/null)"
			done 
		} | column -ts '^'
	)"

	local USAGE__options="
		-n, --namespace   set the namespace
		-k, --context     set the context
	"

	local USAGE__description="
		Provides 'k' (kubectl), 'h' (helm), and 'f' (flux) shorthands to the respective
		utility. These functions leverage redis and scwrypts environments to
		allow quick selection of contexts and namespaces usable across all
		active shell instances.
		
		The scwrypts group 'kubectl' has simple selection executables for
		kubecontext and namespace, but also provides the library to enable
		enriched, use-case-sensitive setup of kubernetes context.

		All actions are scoped to the current SCWRYPTS_ENV
		  currently : \\033[0;33m$SCWRYPTS_ENV\\033[0m
		  
		"

	##########################################
	
	local USER_ARGS=()

	local CUSTOM_COMMAND=0
	local VERBOSE=0
	local HELP=0
	local ERRORS=0

	local COMMAND_SWITCH_CASE="@($(echo $CUSTOM_COMMANDS | sed 's/ /|/g'))"

	[ ! $SUBSESSION ] && local SUBSESSION=0
	[[ $1 =~ ^[0-9]$ ]] && SUBSESSION=$1 && shift 1

	while [[ $# -gt 0 ]]
	do
		case $1 in
			meta )
				CUSTOM_COMMAND=$1
				SCWRYPTS_KUBECTL_CUSTOM_COMMAND_PARSE__$1 ${@:2}
				break
				;;

			-v | --verbose ) VERBOSE=1 ;;
			-h | --help    ) HELP=1 ;;

			--subsession ) SUBSESSION=$2; shift 1 ;;

			-n | --namespace )
				_SCWRYPTS_KUBECTL_DRIVER kubectl meta set namespace $2
				shift 1
				;;

			-k | --context | --kube-context )
				_SCWRYPTS_KUBECTL_DRIVER kubectl meta set context $2
				shift 1
				;;

			-- )
				echo $USER_ARGS | grep -q 'exec' && USER_ARGS+=(--)
				shift 1
				break
				;;

			* )
				[ ! $CUSTOM_COMMAND ] && {
					for C in ${CUSTOM_COMMANDS[@]}
					do
						[[ $1 =~ ^$C$ ]] && {
							SCWRYPTS_KUBECTL_CUSTOM_COMMAND_PARSE__$1 ${@:2}
							break
						}
					done
				}
				USER_ARGS+=($1)
				;;
		esac
		shift 1
	done

	while [[ $# -gt 0 ]]; do USER_ARGS+=($1); shift 1; done


	CHECK_ERRORS --no-fail || return 1

	[[ $HELP -eq 1 ]] && { USAGE; return 0; }

	#####################################################################

	local STRICT=$(_SCWRYPTS_KUBECTL_SETTINGS get strict || echo 1)

	case $CUSTOM_COMMAND in
		0 )
			local CLI_ARGS=()

			local CONTEXT=$(k meta get context)
			local NAMESPACE=$(k meta get namespace)

			[ $CONTEXT ] && [[ $CLI =~ ^helm$    ]] && CLI_ARGS+=(--kube-context $CONTEXT)
			[ $CONTEXT ] && [[ $CLI =~ ^kubectl$ ]] && CLI_ARGS+=(--context $CONTEXT)
			[ $CONTEXT ] && [[ $CLI =~ ^flux$    ]] && CLI_ARGS+=(--context $CONTEXT)

			[[ $STRICT -eq 1 ]] && {
				[ $CONTEXT   ] || echo.error "missing kubectl 'context'"
				[ $NAMESPACE ] || echo.error "missing kubectl 'namespace'"

				CHECK_ERRORS --no-fail --no-usage || {
					echo.error "with 'strict' settings enabled, context and namespace must be set!"
					echo.reminder "
						these values can be set directly with
							$(echo $CLI | head -c1) meta set (namespace|context)
					"

					return 2
				}
			}

			[ $NAMESPACE ] && CLI_ARGS+=(--namespace $NAMESPACE)
			[[ $VERBOSE -eq 1 ]] && {
				echo.reminder "
					context '$CONTEXT'
					namespace '$NAMESPACE'
					environment '$SCWRYPTS_ENV'
					subsession '$SUBSESSION'
					"
				echo.status "running $CLI ${CLI_ARGS[@]} ${USER_ARGS[@]}"
			} || {
				[[ $(_SCWRYPTS_KUBECTL_SETTINGS get context) =~ ^show$ ]] && {
					echo.reminder "$SCWRYPTS_ENV.$SUBSESSION : $CLI ${CLI_ARGS[@]} ${USER_ARGS[@]}"
				}
			}
			$CLI ${CLI_ARGS[@]} ${USER_ARGS[@]}
			;;
		* ) SCWRYPTS_KUBECTL_CUSTOM_COMMAND__$CUSTOM_COMMAND ${USER_ARGS[@]} ;;
	esac
}

_SCWRYPTS_KUBECTL_SETTINGS() {
	# (get setting-name) or (set setting-name setting-value)
	REDIS h$1 ${SCWRYPTS_ENV}:kubectl:settings ${@:2} | grep .
}

#####################################################################
source ${0:a:h}/kubectl.completion.zsh
source ${0:a:h}/meta.zsh
