#####################################################################

DEPENDENCIES+=(
	aws
)

REQUIRED_ENV+=()

#####################################################################

AWS() {
	local ARGS=()

	ARGS+=(--output json)

	[ ! $CI ] && {
		REQUIRED_ENV=(AWS_REGION AWS_ACCOUNT AWS_PROFILE) CHECK_ENVIRONMENT || return 1
		ARGS+=(--profile $AWS_PROFILE)
		ARGS+=(--region $AWS_REGION)
		}

	aws ${ARGS[@]} $@
}
