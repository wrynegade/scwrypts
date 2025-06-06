${scwryptsmodule}.locals() {
	local CLUSTER_NAME

	# set to 'allowed' to enable interactive cluster select
	# by default, the '--cluster-name' flag is required
	local EKS_CLUSTER_NAME_INTERACTIVE
}

${scwryptsmodule}() {
	local PARSED=0

	case $1 in
		( -c | --cluster-name )
			CLUSTER_NAME="$2"
			((PARSED+=2))
			;;
	esac

	return $PARSED
}

${scwryptsmodule}.usage() {
	[[ "$USAGE__usage" =~ '\[...options...\]' ]] || USAGE__usage+=' [...options...]'

	USAGE__options+="\n
		-c, --cluster-name <string>   EKS cluster name identifier string
	"
}

${scwryptsmodule}.validate() {
	[ $CLUSTER_NAME ] && return 0

	[[ $EKS_CLUSTER_NAME_INTERACTIVE =~ allowed ]] \
		|| echo.error 'missing cluster name' \
		|| return

	CLUSTER_NAME=$(\
		$AWS eks list-clusters \
			| jq -r '.[] | .[]' \
			| utils.fzf "select an eks cluster ($ACCOUNT/$REGION)" \
	)

	[ $CLUSTER_NAME ] || echo.error 'must select a valid cluster or use --cluster-name'
}
