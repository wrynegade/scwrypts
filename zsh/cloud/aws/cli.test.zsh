#####################################################################

use test/unittest
use test/mock

use cloud/aws/cli

#####################################################################

beforeeach() {
	MOCK aws
	MOCK DEBUG

	_ARGS=($(uuidgen) $(uuidgen) $(uuidgen))

	_AWS_REGION=$(uuidgen)
	_AWS_PROFILE=$(uuidgen)

	MOCK__ENV AWS_ACCOUNT --value $(uuidgen)
	MOCK__ENV AWS_PROFILE --value ${_AWS_PROFILE}
	MOCK__ENV AWS_REGION  --value ${_AWS_REGION}
}

aftereach() {
	unset _AWS_REGION
	unset _AWS_PROFILE
}

AWS.test.forwards_arguments() {
	AWS ${_ARGS[@]}

	aws.assert.callstack \
		--output json \
		--region ${_AWS_REGION} \
		--profile ${_AWS_PROFILE} \
		${_ARGS[@]} \
		;
}

AWS.test.overrides_region() {
	local OVERRIDE_REGION=$(uuidgen)

	AWS --region ${OVERRIDE_REGION} ${_ARGS[@]}

	aws.assert.callstack \
		--output json \
		--region ${OVERRIDE_REGION} \
		--profile ${_AWS_PROFILE} \
		${_ARGS[@]} \
		;
}

AWS.test.overrides_account() {
	local OVERRIDE_ACCOUNT=$(uuidgen)

	AWS --account ${OVERRIDE_ACCOUNT} ${_ARGS[@]}

	DEBUG.assert.callstackincludes \
		AWS_ACCOUNT=${OVERRIDE_ACCOUNT} \
		;
}
