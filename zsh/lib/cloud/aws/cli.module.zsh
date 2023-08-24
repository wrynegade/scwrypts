#####################################################################

DEPENDENCIES+=(
	aws
)

REQUIRED_ENV+=()

#####################################################################

AWS() {
	REQUIRED_ENV=(AWS_REGION AWS_ACCOUNT AWS_PROFILE) CHECK_ENVIRONMENT || return 1

	aws \
		--profile $AWS_PROFILE \
		--region  $AWS_REGION \
		--output  json \
		$@
}
