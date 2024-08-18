#####################################################################

use cloud/aws/eks/cluster-login

use cloud/aws/zshparse
use cloud/aws/eks/zshparse

#####################################################################

${scwryptsmodule}() {
	eval "$(USAGE.reset)"
	local USAGE__description='
		Context wrapper for kubernetes CLI commands on AWS EKS. This
		will automatically attempt login for first-time connections,
		and ensures the correct kubecontext is used for the expected
		command.

			EKS --cluster-name my-cluster kubectl get pods
			EKS --cluster-name my-cluster helm history my-deployment
			... etc ...
	'

	local \
		ACCOUNT REGION AWS_PASSTHROUGH=() \
		CLUSTER_NAME \
		KUBECLI ARGS=() \
		PARSERS=(
			cloud.aws.zshparse.overrides
			cloud.aws.eks.zshparse.cluster-name
		)

	eval "$ZSHPARSEARGS"

	##########################################

	local CONTEXT="arn:aws:eks:${REGION}:${ACCOUNT}:cluster/${CLUSTER_NAME}"

	local ALREADY_LOGGED_IN
	kubectl config get-contexts --output=name | grep -q "^${CONTEXT}$" \
		&& ALREADY_LOGGED_IN=true \
		|| ALREADY_LOGGED_IN=false \
		;

	case ${ALREADY_LOGGED_IN} in
		( true ) ;;
		( false )
			cloud.aws.eks.cluster-login \
					${AWS_PASSTHROUGH[@]} \
					--cluster-name ${CLUSTER_NAME} \
					>/dev/null \
				|| ERROR "unable to login to cluster '${CLUSTER_NAME}'" \
				|| return 1
			;;
	esac

	local CONTEXT_ARGS=()
	case ${KUBECLI} in
		( helm )
			CONTEXT_ARGS+=(--kube-context ${CONTEXT})  # *rolls eyes* THANKS, helm
			;;
		( * )
			CONTEXT_ARGS+=(--context ${CONTEXT})
			;;
	esac

	${KUBECLI} ${CONTEXT_ARGS[@]} ${ARGS[@]}
}

#####################################################################

${scwryptsmodule}.parse() {
	# local KUBECLI   extracted from default ARGS parser
	return 0
}


${scwryptsmodule}.parse.usage() {
	USAGE__usage+=' kubecli [...kubecli-args...]'

	USAGE__args+='
		kubecli        cli which uses kubernetes context arguments (e.g. kubectl, helm, flux)
		kubecli-args   arguments forwarded to the kubectl-style CLI
	'
}

${scwryptsmodule}.parse.validate() {
	KUBECLI="${ARGS[1]}"
	ARGS=(${ARGS[@]:1})

	[ ${KUBECLI} ] \
		|| ERROR "missing argument for 'kubecli'"
}
