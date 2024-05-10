#####################################################################

use unittest
testmodule=cloud.aws.eksctl.iamserviceaccount.check-exists

#####################################################################

beforeall() {
	use cloud/aws/eksctl/iamserviceaccount/check-exists
	use cloud/aws/eks/cli
}

beforeeach() {
	_SERVICEACCOUNT=$(uuidgen)
	_NAMEPACE=$(uuidgen)
	_ROLE_NAME=$(uuidgen)
	_ROLE_ARN="$(uuidgen)/${_ROLE_NAME}"

	unittest.mock.env AWS_ACCOUNT --value $(uuidgen)
	unittest.mock.env AWS_PROFILE --value $(uuidgen)
	unittest.mock.env AWS_REGION  --value $(uuidgen)

	_ARGS=(
		--serviceaccount ${_SERVICEACCOUNT}
		--namespace ${_NAMEPACE}
		--role-name ${_ROLE_NAME}
	)
}

aftereach() {
	unset _SERVICEACCOUNT _NAMESPACE _ROLE_NAME _ARGS
}

#####################################################################

test.detects-exists() {
	unittest.mock cloud.aws.eks.cli \
		--stdout '{"metadata":{"annotations":{"eks.amazonaws.com/role-arn":"'$_ROLE_ARN'"}}}' \
		;

	${testmodule} ${_ARGS[@]}

	[[ $? -eq 0 ]]
}

test.detects-not-exists() {
	unittest.mock cloud.aws.eks.cli \
		--stdout '{}'

	${testmodule} ${_ARGS[@]}

	[[ $? -eq 100 ]]
}

test.detects-exists-but-does-not-match() {
	unittest.mock cloud.aws.eks.cli \
		--stdout '{"metadata":{"annotations":{"eks.amazonaws.com/role-arn":"'$(uuidgen)'"}}}' \
		;

	${testmodule} ${_ARGS[@]}

	[[ $? -eq 200 ]]
}
