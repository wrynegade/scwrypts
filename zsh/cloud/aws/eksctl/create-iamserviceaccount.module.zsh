#####################################################################

use cloud/aws/eksctl/create-iamserviceaccount.zshparse

#####################################################################

EKSCTL__CREATE_IAMSERVICEACCOUNT() {
	eval "$(usage.reset)"
	local USAGE__description="
		Safe context wrapper for eksctl commands; prevents accidental local environment
		bleed-through, but otherwise works exactly like 'eksctl'.

		This wrapper should be used in place of _all_ 'eksctl' usages within scwrypts.
	"

	USAGE__args+="
		args   all remaining arguments are forwarded to 'eksctl create iamserviceaccount'

		eksctl create iamserviceaccount args:
		$(eksctl create iamserviceaccount --help 2>&1 | grep -v -- '--name' | grep -v -- '--namespace' | grep -v -- '--role-name' | sed 's/^/  /')
	"

	: \
		&& utils.environment.check AWS_REGION \
		&& utils.environment.check AWS_ACCOUNT \
		|| return 1

	local \
		SERVICEACCOUNT NAMESPACE ROLE_NAME ARGS=() FORCE=false \
		ARGS=() ARGS_FORCE=allowed \
		PARSERS=(
			ARGS_PARSER__EKSCTL__CREATE_IAMSERVICEACCOUNT
		)

	eval "$ZSHPARSEARGS"

	##########################################

	[[ $FORCE =~ false ]] && {
		_EKS__CHECK_IAMSERVICEACCOUNT_EXISTS
		case $? in
			0 ) echo.success "'$NAMESPACE/$SERVICEACCOUNT' already configured with '$ROLE_NAME'"
				return 0
				;;
			1 ) # role does not exist yet; continue with rollout
				;;
			2 ) echo.error "'$NAMESPACE/$SERVICEACCOUNT' has been configured with a different role than '$ROLE_NAME'"
				echo.reminder "must use --force flag to overwrite"
				return 2
				;;
		esac
	}

	echo.status "creating iamserviceaccount" \
		&& EKSCTL create iamserviceaccount \
			--cluster $CLUSTER_NAME \
			--namespace $NAMESPACE \
			--name $SERVICEACCOUNT \
			--role-name $ROLE_NAME \
			--override-existing-serviceaccounts \
			--approve \
			${ARGS[@]} \
		&& echo.success "successfully configured '$NAMESPACE/$SERVICEACCOUNT' with IAM role '$ROLE_NAME'" \
		|| { echo.error "unable to configure '$NAMESPACE/$SERVICEACCOUNT' with IAM role '$ROLE_NAME' (check cloudformation dashboard for details)"; return 3; }
}

_EKS__CHECK_IAMSERVICEACCOUNT_EXISTS() {
	echo.status "checking for existing role-arn"
	local CURRENT_ROLE_ARN=$(
		EKS__KUBECTL --namespace $NAMESPACE get serviceaccount $SERVICEACCOUNT -o yaml \
			| utils.yq -r '.metadata.annotations["eks.amazonaws.com/role-arn"]' \
			| grep -v '^null$' \
	)

	[ $CURRENT_ROLE_ARN ] || {
		echo.status "serviceaccount does not exist or has no configured role"
		return 1
	}

	[[ $CURRENT_ROLE_ARN =~ "$ROLE_NAME$" ]] || {
		echo.status "serviceaccount current role does not match desired role:
			  CURRENT : $CURRENT_ROLE_ARN
			  DESIRED : arn:aws:iam::${AWS_ACCOUNT}:role/$ROLE_NAME
			  "
		return 2
	}

	echo.status "serviceaccount current role matches desired role"
	return 0
}
