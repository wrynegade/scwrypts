[[ $SCWRYPTS_KUBECTL_DRIVER_READY -eq 1 ]] && return 0

k() { _SCWRYPTS_KUBECTL_DRIVER kubectl $@; }
h() { _SCWRYPTS_KUBECTL_DRIVER helm $@; }

_SCWRYPTS_KUBECTL_DRIVER() {
	[ ! $SCWRYPTS_ENV ] && {
		ERROR "must set SCWRYPTS_ENV in order to use '$(echo $CLI | head -c1)'"
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

	local USAGE_ARGS="$(for C in ${CUSTOM_COMMANDS[@]}; do echo "  - $C"; done)"
	local USAGE_OPTIONS="
	  -n, --namespace   set the namespace for commands in '$SCWRYPTS_ENV'
	  -k, --context     set the context for commands in '$SCWRYPTS_ENV'
	"
	local DESCRIPTION="
		Provides 'k' (kubectl) and 'h' (helm) shorthands to the
		respective utility. These functions leverage redis and scwrypts
		environments to allow quick selection of contexts and namespaces
		usable across all active shell instances.
		
		The scwrypts group 'kubectl' has simple selection executables
		for kubecontext and namespace, but also provides the library to
		enable enriched, use-case-sensitive setup of kubernetes context.
		"	

	local USAGE="
		usage: $(echo $CLI | head -c1) [...args...] [...options...] -- [...$CLI options...]

		args: -

		options: -
		  -h, --help      display this help dialogue
		  -v, --verbose   output debugging information

		DESCRIPTION
	"

	##########################################

	local USER_ARGS=()

	local CUSTOM_COMMAND=0
	PARAMETER_OVERRIDES+=
	local VERBOSE=0

	while [[ $# -gt 0 ]]
	do
		case $1 in
			-v | --verbose ) VERBOSE=1 ;;
			-n | --namespace )
				echo "TODO: set namespace ('$2')" >&2
				USER_ARGS+=(--namespace $2); shift 1
				;;

			-k | --context | --kube-context )
				echo "TODO: set context ('$2')" >&2
				[[ $CLI =~ ^helm$    ]] && USER_ARGS+=(--kube-context $2)
				[[ $CLI =~ ^kubectl$ ]] && USER_ARGS+=(--context $2)
				shift 1
				;;

			meta )
				CUSTOM_COMMAND=meta
				USAGE_ARGS="  - get\n  - set"
				USAGE_OPTIONS=''
				DESCRIPTION="perform meta-operations on $(echo $CLI | head -c1) for '$SCWRYPTS_ENV'"

				case $2 in
					-h | --help ) HELP=1 ;;

					set ) 
						USAGE_ARGS="  set (namespace|context)"
						DESCRIPTION="interactively set a namespace or context for '$SCWRYPTS_ENV'"
						case $3 in
							namespace | context ) USER_ARGS+=($2 $3) ;;
							-h | --help ) HELP=1 ;;

							* ) ERROR "cannot set '$3'" >&2 ;;
						esac
						shift 1
						;;

					get )
						USAGE_ARGS="  get (namespace|context)"
						DESCRIPTION="output the current namespace or context for '$SCWRYPTS_ENV'"
						case $3 in
							namespace | context ) USER_ARGS+=($2 $3) ;;
							-h | --help ) HELP=1 ;;

							* ) ERROR "cannot get '$3'" >&2 ;;
						esac
						shift 1
						;;
				esac
				shift 1
				;;

			-h | --help ) HELP=1 ;;
			-- ) shift 1; break ;;
			 * ) USER_ARGS+=($1) ;;
		esac
		shift 1
	done

	while [[ $# -gt 0 ]]; do USER_ARGS+=($1); shift 1; done


	CHECK_ERRORS --no-fail 2>&1 | sed 's/scwrypts -- //' >&2 || return 1

	[[ $HELP -eq 1 ]] && {
		[[ ! $CUSTOM_COMMAND =~ ^0$ ]] \
			&& USAGE=$(echo $USAGE | sed "s/[[]\\.\\.\\.args\\.\\.\\.[]]/$CUSTOM_COMMAND &/")

		USAGE=$(echo $USAGE | perl -pe "
			s/args: -/args:\n$USAGE_ARGS/;
			s^options: -^options:$USAGE_OPTIONS^;
			s/DESCRIPTION/$DESCRIPTION/;
			")

		USAGE 2>&1 | sed 's/scwrypts -- //' >&2
		return 0
	}

	#####################################################################

	case $CUSTOM_COMMAND in
		0 )
			local CLI_ARGS=()

			local CONTEXT=$(k meta get context)
			local NAMESPACE=$(k meta get namespace)

			[ $CONTEXT ] && [[ $CLI =~ ^helm$    ]] && CLI_ARGS+=(--kube-context $CONTEXT)
			[ $CONTEXT ] && [[ $CLI =~ ^kubectl$ ]] && CLI_ARGS+=(--context $CONTEXT)

			[ $NAMESPACE ] && CLI_ARGS+=(--namespace $NAMESPACE)
			[[ $VERBOSE -eq 1 ]] && {
				INFO "
					using context '$CONTEXT'
					using namespace '$NAMESPACE'
					"
				STATUS "running $CLI ${CLI_ARGS[@]} ${USER_ARGS[@]}"
			}
			$CLI ${CLI_ARGS[@]} ${USER_ARGS[@]}
			;;
		* ) eval 'SCWRYPTS_KUBECTL_CUSTOM_COMMAND__'$CUSTOM_COMMAND ${USER_ARGS[@]} ;;
	esac
}

SCWRYPTS_KUBECTL_CUSTOM_COMMAND__meta() {
	case $1 in
		get ) REDIS get --prefix current:$2; return 0 ;;
		set ) scwrypts --name set-$2 --type zsh --group kubectl ;;
	esac
}

#####################################################################
source ${0:a:h}/kubectl.driver.completion.zsh
