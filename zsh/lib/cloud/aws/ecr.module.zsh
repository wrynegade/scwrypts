#####################################################################

DEPENDENCIES+=(
	docker
)

REQUIRED_ENV+=(
	AWS_ACCOUNT
	AWS_REGION
)

use cloud/aws/cli

#####################################################################

ECR_LOGIN() {
	STATUS "performing AWS ECR docker login"
	AWS ecr get-login-password \
		| docker login \
			--username AWS \
			--password-stdin \
			"$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com" \
		&& SUCCESS "authenticated docker for '$AWS_ACCOUNT' in '$AWS_REGION'" \
		|| {
			ERROR "unable to authenticate docker for '$AWS_ACCOUNT' in '$AWS_REGION'"
			return 1
		}
}
