#####################################################################

use cloud/aws/cli
use cloud/aws/zshparse

DEPENDENCIES+=(docker)

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		Performs the appropriate 'docker login' command with temporary
		credentials from AWS.
	"

	local PARSERS=(cloud.aws.zshparse.overrides)

	eval "$(utils.parse.autosetup)"

	##########################################

	${AWS} ecr get-login-password \
		| docker login "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com" \
			--username AWS \
			--password-stdin \
			&>/dev/null \
		&& echo.success "authenticated docker for '${ACCOUNT}' in '${REGION}'" \
		|| echo.error "unable to authenticate docker for '${ACCOUNT}' in '${REGION}'" \
		;
}
