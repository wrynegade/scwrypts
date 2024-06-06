AWS_PARSER__OVERRIDES() {
	# local ACCOUNT REGION                        parsed/configured $AWS_ACCOUNT and $AWS_REGION (use this instead of direct env-var)
	# local AWS=() AWS_PASSTHROUGH=()             used to forward parsed overrides to AWS calls (e.g. 'AWS ${AWS_PASSTHROUGH[@]} your command' or '$AWS your command')
	# local AWS_EVAL_PREFIX AWS_CONTEXT_ARGS=()   should only be used by lib/cloud/aws/cli:AWS
	local PARSED=0

	case $1 in
		--account ) PARSED+=2; ACCOUNT=$2 ;;
		--region  ) PARSED+=2; REGION=$2  ;;
	esac

	return $PARSED
}

AWS_PARSER__OVERRIDES__usage() {
	[[ "$USAGE__usage" =~ ' \[...options...\]' ]] || USAGE__usage+=' [...options...]'

	USAGE__options+="\n
		--account   overrides required AWS_ACCOUNT scwrypts env value
		--region    overrides required AWS_REGION scwrypts env value
	"
}


AWS_PARSER__OVERRIDES__validate() {
	AWS_CONTEXT_ARGS=(--output json)

	[ $ACCOUNT ] || { __CHECK_ENV_VAR AWS_ACCOUNT &>/dev/null && ACCOUNT=$AWS_ACCOUNT; }
	[ $ACCOUNT ] \
		&& AWS_EVAL_PREFIX+="AWS_ACCOUNT=$ACCOUNT " \
		&& AWS_PASSTHROUGH+=(--account $ACCOUNT) \
		|| ERROR "missing either --account or AWS_ACCOUNT" \
		;

	[ $REGION ] || { __CHECK_ENV_VAR AWS_REGION &>/dev/null && REGION=$AWS_REGION; }
	[ $REGION ] \
		&& AWS_EVAL_PREFIX+="AWS_REGION=$REGION AWS_DEFAULT_REGION=$REGION " \
		&& AWS_CONTEXT_ARGS+=(--region $REGION) \
		&& AWS_PASSTHROUGH+=(--region $REGION) \
		|| ERROR "missing either --region  or AWS_REGION" \
		;

	__CHECK_ENV_VAR AWS_PROFILE &>/dev/null
	[ $AWS_PROFILE ] \
		&& AWS_EVAL_PREFIX+="AWS_PROFILE=$AWS_PROFILE " \
		&& AWS_CONTEXT_ARGS+=(--profile $AWS_PROFILE) \
		;

	AWS=(AWS ${AWS_PASSTHROUGH[@]})

	[ ! $CI ] && {
		# non-CI must use PROFILE authentication
		[ $AWS_PROFILE ] || ERROR "missing either --profile or AWS_PROFILE";

		[[ $AWS_PROFILE =~ ^default$ ]] \
			&& WARNING "it is HIGHLY recommended to NOT use the 'default' profile for aws operations\nconsider using '$USER.$SCWRYPTS_ENV' instead"
	}

	[ $CI ] && {
		# CI can use 'profile' or envvar 'access key' authentication
		[ $AWS_PROFILE ] && return 0  # 'profile' preferred

		[ $AWS_ACCESS_KEY_ID ] && [ $AWS_SECRET_ACCESS_KEY ] \
			&& AWS_EVAL_PREFIX+="AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID " \
			&& AWS_EVAL_PREFIX+="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY " \
			&& return 0

		ERROR "running in CI, but missing both profile and access-key configuration\n(one AWS authentication method *must* be used)"
	}
}
