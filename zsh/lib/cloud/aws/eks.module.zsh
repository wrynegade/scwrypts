#####################################################################

DEPENDENCIES+=(kubectl yq)

use cloud/aws/cli
use cloud/aws/zshparse
use cloud/aws/zshparse/eks

#####################################################################

EKS() {
	eval "$(USAGE__reset)"
	local USAGE__description='
		Allows access to kubernetes CLI commands by configuring environment
		to point to a specific cluster.
	'

	local \
		ACCOUNT REGION AWS_PASSTHROUGH=() \
		CLUSTER_NAME \
		KUBECLI ARGS=() \
		PARSERS=(
			AWS_PARSER__OVERRIDES
			AWS_PARSER__EKS_CLUSTER_NAME
			ARGS_PARSER__EKS
		)

	eval "$ZSHPARSEARGS"

	#####################################################################
	local CONTEXT="arn:aws:eks:${REGION}:${ACCOUNT}:cluster/${CLUSTER_NAME}"

	kubectl config get-contexts --output=name | grep -q "^$CONTEXT$" || {
		EKS__CLUSTER_LOGIN \
				${AWS_PASSTHROUGH[@]} \
				--cluster-name $CLUSTER_NAME \
				>/dev/null \
			|| ERROR "unable to login to cluster '$CLUSTER_NAME'" \
			|| return 1
	}

	local CONTEXT_ARGS=()
	case $KUBECLI in
		helm ) CONTEXT_ARGS+=(--kube-context $CONTEXT) ;;
		   * ) CONTEXT_ARGS+=(--context      $CONTEXT) ;;
	esac

	$KUBECLI ${CONTEXT_ARGS[@]} ${ARGS[@]}
}

#####################################################################

EKS__CLUSTER_LOGIN() {
	eval "$(USAGE__reset)"
	local USAGE__description='
		Interactively sets the default kubeconfig to match the selected
		cluster in EKS. Also creates the kubeconfig entry if it does not
		already exist.
	'

	local \
		ACCOUNT REGION AWS=() \
		CLUSTER_NAME EKS_CLUSTER_NAME_INTERACTIVE=allowed \
		PARSERS=(
			AWS_PARSER__OVERRIDES
			AWS_PARSER__EKS_CLUSTER_NAME
		)

	eval "$ZSHPARSEARGS"

	#####################################################################

	[ $CLUSTER_NAME ] || CLUSTER_NAME=$(\
		$AWS eks list-clusters \
			| jq -r '.[] | .[]' \
			| FZF "select an eks cluster ($ACCOUNT/$REGION)"
	)

	[ $CLUSTER_NAME ] || ERROR 'must select a valid cluster or use --cluster-name'

	CHECK_ERRORS --no-fail || return $?

	##########################################

	STATUS 'updating kubeconfig for EKS cluster '$CLUSTER_NAME''
	$AWS eks update-kubeconfig --name $CLUSTER_NAME \
		&& SUCCESS "kubeconfig updated with '$CLUSTER_NAME'" \
		|| ERROR "failed to update kubeconfig; do you have permission to access '$CLUSTER_NAME'?"
}
