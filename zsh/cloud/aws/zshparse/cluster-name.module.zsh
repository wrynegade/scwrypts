AWS_PARSER__EKS_CLUSTER_NAME() {
	# local CLUSTER_NAME

	local PARSED=0

	case $1 in
		-c | --cluster-name )
			CLUSTER_NAME="$2"
			((PARSED+=2))
			;;
	esac

	return $PARSED
}


AWS_PARSER__EKS_CLUSTER_NAME__usage() {
	[[ "$USAGE__usage" =~ '\[...options...\]' ]] || USAGE__usage+=' [...options...]'

	USAGE__options+="\n
		-c, --cluster-name <string>   EKS cluster name identifier string
	"
}

AWS_PARSER__EKS_CLUSTER_NAME__validate() {
	[ $CLUSTER_NAME ] && return 0

	[[ $EKS_CLUSTER_NAME_INTERACTIVE =~ allowed ]] \
		|| ERROR 'missing cluster name' \
		|| return

	CLUSTER_NAME=$(\
		$AWS eks list-clusters \
			| jq -r '.[] | .[]' \
			| FZF "select an eks cluster ($ACCOUNT/$REGION)" \
	)

	[ $CLUSTER_NAME ] || ERROR 'must select a valid cluster or use --cluster-name'
}
