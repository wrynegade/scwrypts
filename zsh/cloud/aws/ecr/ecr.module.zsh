#####################################################################

DEPENDENCIES+=(docker)

use cloud/aws/cli
use cloud/aws/zshparse

#####################################################################

ECR_LOGIN() {
	eval "$(USAGE.reset)"
	local USAGE__description="
		Performs the appropriate 'docker login' command with temporary
		credentials from AWS.
	"

	local \
		ACCOUNT REGION AWS=() \
		PARSERS=(
			AWS_PARSER__OVERRIDES
		)

	eval "$ZSHPARSEARGS"

	STATUS "performing AWS ECR docker login"
	$AWS ecr get-login-password \
		| docker login "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com" \
			--username AWS \
			--password-stdin \
		&& SUCCESS "authenticated docker for '$ACCOUNT' in '$REGION'" \
		|| ERROR "unable to authenticate docker for '$ACCOUNT' in '$REGION'" \
		;
}
