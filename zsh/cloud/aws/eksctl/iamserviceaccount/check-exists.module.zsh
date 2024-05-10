#####################################################################

use cloud/aws/eks/cli

use cloud/aws/eksctl/iamserviceaccount/zshparse
use cloud/aws/zshparse/overrides

DEPENDENCIES+=(kubectl yq)

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		determine whether the target iamserviceaccount already
		exists on Kubernetes

		OK:
		  exit code   0 : the serviceaccount exists on kubernetes
		  exit code 100 : the serviceaccount does not exist on kubernetes

		ERROR:
		  exit code 200 : the serviceaccount exists on kubernetes, but does not match the target role
	"

	local PARSERS=(
		cloud.aws.eksctl.iamserviceaccount.zshparse
		cloud.aws.zshparse.overrides
	)

	eval "$(utils.parse.autosetup)"

	##########################################

	echo.status "checking for existing role-arn"
	local CURRENT_ROLE_ARN=$(
		cloud.aws.eks.cli kubectl ${AWS_PASSTHROUGH_ARGS[@]} --namespace "${NAMESPACE}" get serviceaccount "${SERVICEACCOUNT}" -o yaml \
			| utils.yq -r '.metadata.annotations["eks.amazonaws.com/role-arn"]' \
			| grep -v '^null$' \
	)

	[ "${CURRENT_ROLE_ARN}" ] || {
		echo.status "serviceaccount does not exist or has no configured role"
		return 100
	}

	[[ ${CURRENT_ROLE_ARN} =~ "${ROLE_NAME}$" ]] || {
		echo.status "\
			serviceaccount current role does not match desired role:
			  CURRENT : ${CURRENT_ROLE_ARN}
			  DESIRED : arn:aws:iam::${AWS_ACCOUNT}:role/${ROLE_NAME}
		"
		return 200
	}

	echo.status "serviceaccount current role matches desired role"
	return 0
}
