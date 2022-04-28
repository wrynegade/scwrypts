source ${0:a:h}/../common.zsh

__CHECK_DEPENDENCIES \
	aws \
	jq \
	;

__CHECK_ENV_VARS \
	_AWS_ACCOUNT \
	_AWS_PROFILE \
	_AWS_REGION \
	;

#####################################################################

_AWS() { aws --profile $_AWS_PROFILE --region $_AWS_REGION --output json $@; }
