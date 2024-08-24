#####################################################################

use unittest
testmodule=cloud.aws.eksctl.iamserviceaccount.create

#####################################################################

beforeall() {
	use cloud/aws/eksctl/iamserviceaccount/create
}

beforeeach() {
	unittest.mock cloud.aws.eksctl.cli

	_SERVICEACCOUNT=$(uuidgen)
	_NAMESPACE=$(uuidgen)
	_ROLE_NAME=$(uuidgen)
	_ROLE_ARN="$(uuidgen)/${_ROLE_NAME}"

	_CLUSTER_NAME=$(uuidgen)

	_AWS_ACCOUNT=$(uuidgen)
	_AWS_REGION=$(uuidgen)

	unittest.mock.env AWS_ACCOUNT --value ${_AWS_ACCOUNT}
	unittest.mock.env AWS_PROFILE --value $(uuidgen)
	unittest.mock.env AWS_REGION  --value ${_AWS_REGION}

	_IAMSERVICEACCOUNT_ARGS=(
		--serviceaccount ${_SERVICEACCOUNT}
		--namespace ${_NAMESPACE}
		--role-name ${_ROLE_NAME}
	)

	_EXTRA_ARGS=($(uuidgen) $(uuidgen) $(uuidgen))

	_ARGS=(
		--cluster-name ${_CLUSTER_NAME}
		${_IAMSERVICEACCOUNT_ARGS[@]}
		--
		${_EXTRA_ARGS[@]}
	)

	_EXPECTED_AWS_PASSTHROUGH=(
		--account ${_AWS_ACCOUNT}
		--region  ${_AWS_REGION}
	)
}

aftereach() {
	unset \
		_SERVICEACCOUNT _NAMESPACE _ROLE_NAME \
		_CLUSTER_NAME \
		_AWS_ACCOUNT _AWS_REGION \
		_ARGS _EXPECTED_AWS_PASSTHROUGH_ARGS \
		;
}

#####################################################################

test.performs-check-exists() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 0 \
		;

	${testmodule} ${_ARGS[@]}

	cloud.aws.eksctl.iamserviceaccount.check-exists.assert.callstack \
		${_IAMSERVICEACCOUNT_ARGS[@]} \
		${_EXPECTED_AWS_PASSTHROUGH[@]} \
		;
}

test.ignores-check-exist-on-force() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 0 \
		;

	${testmodule} ${_ARGS[@]} --force

	cloud.aws.eksctl.iamserviceaccount.check-exists.assert.not.called
}

test.does-not-create-if-exists() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 0 \
		;
	
	${testmodule} ${_ARGS[@]}

	cloud.aws.eksctl.cli.assert.not.called
}

test.creates-role() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 100 \
		;
	
	${testmodule} ${_ARGS[@]}

	cloud.aws.eksctl.cli.assert.callstack \
		create iamserviceaccount \
		--cluster   ${_CLUSTER_NAME} \
		--namespace ${_NAMESPACE} \
		--name      ${_SERVICEACCOUNT} \
		--role-name ${_ROLE_NAME} \
		--override-existing-serviceaccounts \
		--approve \
		${_EXTRA_ARGS[@]} \
		;
}

test.creates-role-on-force() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 0 \
		;
	
	${testmodule} ${_ARGS[@]} --force

	cloud.aws.eksctl.cli.assert.callstack \
		create iamserviceaccount \
		--cluster   ${_CLUSTER_NAME} \
		--namespace ${_NAMESPACE} \
		--name      ${_SERVICEACCOUNT} \
		--role-name ${_ROLE_NAME} \
		--override-existing-serviceaccounts \
		--approve \
		${_EXTRA_ARGS[@]} \
		;
}

test.does-not-create-if-mismatched-role() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 200 \
		;
	
	${testmodule} ${_ARGS[@]}

	cloud.aws.eksctl.cli.assert.not.called
}

test.returns-correct-error-if-mismatched-role() {
	unittest.mock cloud.aws.eksctl.iamserviceaccount.check-exists \
		--exit-code 200 \
		;
	
	${testmodule} ${_ARGS[@]}

	[[ $? -eq 2 ]]
}
