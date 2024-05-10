#####################################################################

use unittest
testmodule=cloud.aws.ecr.login

#####################################################################

beforeall() {
	use cloud/aws/ecr/login
}

beforeeach() {
	unittest.mock cloud.aws.cli
	unittest.mock docker

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
		_AWS_ACCOUNT _AWS_PROFILE _AWS_REGION \
		_EXPECTED_AWS_ARGS \
		;
}

#####################################################################

test.login-forwards-credentials-to-docker() {
	${testmodule}

	docker.assert.callstack \
		login "${_AWS_ACCOUNT}.dkr.ecr.${_AWS_REGION}.amazonaws.com" \
			--username AWS \
			--password-stdin \
			;
}
