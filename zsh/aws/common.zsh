_DEPENDENCIES+=(
	aws
	jq
)
_REQUIRED_ENV+=(
	AWS_ACCOUNT
	AWS_PROFILE
	AWS_REGION
)
source ${0:a:h}/../common.zsh
#####################################################################

_AWS() { aws --profile $AWS_PROFILE --region $AWS_REGION --output json $@; }
