#####################################################################

use unittest
testmodule=cloud.aws.eksctl.cli

#####################################################################

beforeall() {
	use cloud/aws/eksctl/cli
}

beforeeach() {
	unittest.mock eksctl
	unittest.mock echo.debug

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

	eksctl.assert.callstack \
		${_ARGS[@]} \
		;
}

test.forwards-profile() {
	#
	# --profile is an invalid argument for eksctl, so it
	# MUST be forwarded as AWS_PROFILE to prevent environment
	# bleeding
	#
	${testmodule} ${_ARGS[@]}

	echo.debug.assert.callstackincludes \
		AWS_PROFILE=${OVERRIDE_REGION} \
		;
}

test.overrides-region() {
	local OVERRIDE_REGION=$(uuidgen)

	${testmodule} --region ${OVERRIDE_REGION} ${_ARGS[@]}

	echo.debug.assert.callstackincludes \
		AWS_REGION=${OVERRIDE_REGION} \
		;
}

test.overrides-account() {
	local OVERRIDE_ACCOUNT=$(uuidgen)

	${testmodule} --account ${OVERRIDE_ACCOUNT} ${_ARGS[@]}

	echo.debug.assert.callstackincludes \
		AWS_ACCOUNT=${OVERRIDE_ACCOUNT} \
		;
}
