#####################################################################

use cloud/aws/cli

use cloud/aws/zshparse
use cloud/aws/eks/zshparse

#####################################################################

${scwryptsmodule}() {
	eval "$(usage.reset)"
	local USAGE__description='
		Interactively sets the default kubeconfig to match the selected
		cluster in EKS. Also creates the kubeconfig entry if it does not
		already exist.
	'

	local \
		ACCOUNT REGION AWS=() AWS_PASSTHROUGH=() \
		CLUSTER_NAME EKS_CLUSTER_NAME_INTERACTIVE=allowed \
		PARSERS=(
			cloud.aws.zshparse.overrides
			cloud.aws.eks.zshparse.cluster-name
		)

	eval "$ZSHPARSEARGS"

	#####################################################################

	[ ${CLUSTER_NAME} ] || CLUSTER_NAME=$(\
		${AWS} eks list-clusters \
			| jq -r '.[] | .[]' \
			| FZF "select an eks cluster (${ACCOUNT}/${REGION})"
	)

	[ ${CLUSTER_NAME} ] || echo.error 'must select a valid cluster or use --cluster-name'

	utils.check-errors --no-fail || return $?

	##########################################

	echo.status 'updating kubeconfig for EKS cluster '${CLUSTER_NAME}''
	${AWS} eks update-kubeconfig --name ${CLUSTER_NAME} \
		&& echo.success "kubeconfig updated with '${CLUSTER_NAME}'" \
		|| echo.error "failed to update kubeconfig; do you have permission to access '${CLUSTER_NAME}'?"
}
