#####################################################################

use unittest
testmodule=cloud.aws.cli

#####################################################################

beforeall() {
	use cloud/aws/cli
}

beforeeach() {
	unittest.mock aws
	unittest.mock DEBUG

	_ARGS=($(uuidgen) $(uuidgen) $(uuidgen))

	_AWS_REGION=$(uuidgen)
	_AWS_PROFILE=$(uuidgen)

	unittest.mock.env AWS_ACCOUNT --value $(uuidgen)
	unittest.mock.env AWS_PROFILE --value ${_AWS_PROFILE}
	unittest.mock.env AWS_REGION  --value ${_AWS_REGION}
}

aftereach() {
	unset _AWS_REGION
	unset _AWS_PROFILE
}

#####################################################################

test.forwards-arguments() {
	${testmodule} ${_ARGS[@]}

	aws.assert.callstack \
		--output json \
		--region ${_AWS_REGION} \
		--profile ${_AWS_PROFILE} \
		${_ARGS[@]} \
		;
}

test.overrides-region() {
	local OVERRIDE_REGION=$(uuidgen)

	${testmodule} --region ${OVERRIDE_REGION} ${_ARGS[@]}

	aws.assert.callstack \
		--output json \
		--region ${OVERRIDE_REGION} \
		--profile ${_AWS_PROFILE} \
		${_ARGS[@]} \
		;
}

test.overrides-account() {
	local OVERRIDE_ACCOUNT=$(uuidgen)

	${testmodule} --account ${OVERRIDE_ACCOUNT} ${_ARGS[@]}

	DEBUG.assert.callstackincludes \
		AWS_ACCOUNT=${OVERRIDE_ACCOUNT} \
		;
}
