#####################################################################

use unittest

testmodule=cloud.aws.eks.cli

#####################################################################

beforeall() {
	use cloud/aws/eks/cli
	use cloud/aws/eks/cluster-login
}

beforeeach() {
	unittest.mock cloud.aws.eks.cluster-login

	_CLUSTER_NAME=$(uuidgen)

	_AWS_ACCOUNT=$(uuidgen)
	_AWS_PROFILE=$(uuidgen)
	_AWS_REGION=$(uuidgen)

	_KUBECLI=$(uuidgen)
	_KUBECLI_ARGS=($(uuidgen) $(uuidgen) $(uuidgen))

	unittest.mock.env AWS_ACCOUNT --value ${_AWS_ACCOUNT}
	unittest.mock.env AWS_PROFILE --value ${_AWS_PROFILE}
	unittest.mock.env AWS_REGION  --value ${_AWS_REGION}

	_EXPECTED_KUBECONTEXT="arn:aws:eks:${_AWS_REGION}:${_AWS_ACCOUNT}:cluster/${_CLUSTER_NAME}"
	_KUBECTL_KUBECONTEXTS="$(uuidgen)\n${_EXPECTED_KUBECONTEXT}\n$(uuidgen)"

	_EXPECTED_AWS_ARGS=(
		--account ${_AWS_ACCOUNT}
		--region  ${_AWS_REGION}
	)
}

aftereach() {
	unset \
		_CLUSTER_NAME \
		_AWS_ACCOUNT _AWS_PROFILE _AWS_REGION \
		_EXPECTED_AWS_ARGS \
		;
}

mock.kubectl() {
	unittest.mock kubectl --stdout "${_KUBECTL_KUBECONTEXTS}"
}

mock.kubecli() {
	command -v ${_KUBECLI} &>/dev/null || ${_KUBECLI}() { true; }
	unittest.mock ${_KUBECLI}
}

#####################################################################

test.uses-correct-kubecli-args() {
	mock.kubectl
	mock.kubecli

	${testmodule} --cluster-name ${_CLUSTER_NAME} ${_KUBECLI} ${_KUBECLI_ARGS[@]}

	${_KUBECLI}.assert.callstack \
		--context ${_EXPECTED_KUBECONTEXT} \
		${_KUBECLI_ARGS[@]}
		;
}

test.uses-correct-helm-args() {
	_KUBECLI=helm

	mock.kubectl
	mock.kubecli

	${testmodule} --cluster-name ${_CLUSTER_NAME} ${_KUBECLI} ${_KUBECLI_ARGS[@]}

	${_KUBECLI}.assert.callstack \
		--kube-context ${_EXPECTED_KUBECONTEXT} \
		${_KUBECLI_ARGS[@]}
		;
}

test.performs-login() {
	_KUBECTL_KUBECONTEXTS="$(uuidgen)\n$(uuidgen)"

	mock.kubectl
	mock.kubecli

	${testmodule} --cluster-name ${_CLUSTER_NAME} ${_KUBECLI} ${_KUBECLI_ARGS[@]}

	cloud.aws.eks.cluster-login.assert.callstack \
		${_EXPECTED_AWS_ARGS[@]} \
		--cluster-name ${_CLUSTER_NAME} \
		;
}

test.does-not-perform-login-if-already-logged-in() {
	mock.kubectl
	mock.kubecli

	${testmodule} --cluster-name ${_CLUSTER_NAME} ${_KUBECLI} ${_KUBECLI_ARGS[@]}

	cloud.aws.eks.cluster-login.assert.not.called
}
