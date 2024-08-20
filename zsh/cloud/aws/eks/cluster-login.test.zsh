#####################################################################

use unittest
testmodule=cloud.aws.eks.cluster-login

#####################################################################

beforeall() {
	use cloud/aws/eks/cluster-login
}

beforeeach() {
	unittest.mock cloud.aws.cli

	_CLUSTER_NAME=$(uuidgen)

	_AWS_ACCOUNT=$(uuidgen)
	_AWS_PROFILE=$(uuidgen)
	_AWS_REGION=$(uuidgen)

	unittest.mock.env AWS_ACCOUNT --value ${_AWS_ACCOUNT}
	unittest.mock.env AWS_PROFILE --value ${_AWS_PROFILE}
	unittest.mock.env AWS_REGION  --value ${_AWS_REGION}

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

#####################################################################

test.login-to-correct-cluster() {
	${testmodule} --cluster-name ${_CLUSTER_NAME}

	cloud.aws.cli.assert.callstack \
		${_EXPECTED_AWS_ARGS[@]} \
		eks update-kubeconfig \
		--name ${_CLUSTER_NAME} \
		;
}

test.interactive-login-ignored-on-ci() {
	${testmodule}
	cloud.aws.cli.assert.not.called
}

test.interactive-login-to-correct-cluster() {
	unittest.mock utils.fzf --stdout ${_CLUSTER_NAME}

	${testmodule}

	cloud.aws.cli.assert.callstack \
		${_EXPECTED_AWS_ARGS[@]} \
		eks update-kubeconfig \
		--name ${_CLUSTER_NAME} \
		;
}
