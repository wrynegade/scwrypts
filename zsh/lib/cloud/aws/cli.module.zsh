#####################################################################

DEPENDENCIES+=(
	aws
)

REQUIRED_ENV+=(
	AWS_ACCOUNT
	AWS_PROFILE
	AWS_REGION
)

#####################################################################

AWS() {
	aws \
		--profile $AWS_PROFILE \
		--region  $AWS_REGION \
		--output  json \
		$@
}
