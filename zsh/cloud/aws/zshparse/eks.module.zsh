ARGS_PARSER__EKS() {
	# local KUBECLI ARGS=()

	local PARSED=0

	case $1 in
		-h | --help ) ;;  # filter to default parser
		* )
			((POSITIONAL_ARGS+=1))
			case $POSITIONAL_ARGS in
				1 ) KUBECLI=$1  # first positional arg is a kuberentes cli (e.g. kubectl, helm, flux)
					;;
				* ) ARGS+=($1)  # assume everything else belongs to the kubernetes cli
					;;
			esac
			((PARSED+=1))
			;;
	esac

	return $PARSED
}


ARGS_PARSER__EKS__usage() {
	USAGE__usage+=' kubecli [...kubecli-args...]'

	USAGE__args+='
		kubecli        cli which uses kubernetes context arguments (e.g. kubectl, helm, flux)
		kubecli-args   arguments forwarded to the kubectl-style CLI
	'
}

ARGS_PARSER__EKS__validate() {
	[ $KUBECLI ] \
		|| ERROR "missing argument for 'kubecli'"
}
