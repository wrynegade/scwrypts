_DEPENDENCIES+=(
	aws
	jq
)
_REQUIRED_ENV+=(
	_AWS_ACCOUNT
	_AWS_PROFILE
	_AWS_REGION
)
source ${0:a:h}/../common.zsh
#####################################################################

_AWS() { aws --profile $_AWS_PROFILE --region $_AWS_REGION --output json $@; }
