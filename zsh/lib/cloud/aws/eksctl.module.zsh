#####################################################################

DEPENDENCIES+=(eksctl)
REQUIRED_ENV+=()

use cloud/aws/eks

#####################################################################

EKSCTL() {
	REQUIRED_ENV=(AWS_PROFILE AWS_REGION) CHECK_ENVIRONMENT || return 1

	AWS_PROFILE=$AWS_PROFILE AWS_REGION=$AWS_REGION \
		eksctl $@
}

EKSCTL__CREATE_IAMSERVICEACCOUNT() {
	local USAGE="
		usage: serviceaccount-name namespace [...options...] -- [...'eksctl create iamserviceaccount' args...]

		options:
		  --serviceaccount   (required) target k8s:ServiceAccount
		  --namespace        (required) target k8s:Namespace
		  --role-name        (required) name of the IAM role to assign

		  --force   don't check for existing serviceaccount and override any existing configuration

		eksctl create iamserviceaccount args:
		$(eksctl create iamserviceaccount --help 2>&1 | grep -v -- '--name' | grep -v -- '--namespace' | grep -v -- '--role-name' | sed 's/^/  /')
	"
	REQUIRED_ENV=(AWS_REGION AWS_ACCOUNT CLUSTER_NAME) CHECK_ENVIRONMENT || return 1

	local SERVICEACCOUNT NAMESPACE ROLE_NAME
	local FORCE=0
	local EKSCTL_ARGS=()

	while [[ $# -gt 0 ]]
	do
		case $1 in
			--serviceaccount ) SERVICEACCOUNT=$2; shift 1 ;;
			--namespace      ) NAMESPACE=$2; shift 1 ;;
			--role-name      ) ROLE_NAME=$2; shift 1 ;;

			--force ) FORCE=1 ;; 

			-- ) shift 1; break ;;

			* ) ERROR "unknown argument '$1'" ;;
		esac
		shift 1
	done

	while [[ $# -gt 0 ]]; do EKSCTL_ARGS+=($1); shift 1; done

	[ $SERVICEACCOUNT ] || ERROR "--serviceaccount is required"
	[ $NAMESPACE      ] || ERROR "--namespace is required"
	[ $ROLE_NAME      ] || ERROR "--role-name is required"

	CHECK_ERRORS --no-fail || return 1

	##########################################
	
	[[ $FORCE -eq 0 ]] && {
		_EKS__CHECK_IAMSERVICEACCOUNT_EXISTS
		local EXISTS_STATUS=$?
		case $EXISTS_STATUS in
			0 )
				SUCCESS "'$NAMESPACE/$SERVICEACCOUNT' already configured with '$ROLE_NAME'"
				return 0
				;;
			1 ) ;; # role does not exist yet; continue with rollout
			2 )
				ERROR "'$NAMESPACE/$SERVICEACCOUNT' has been configured with a different role than '$ROLE_NAME'"
				REMINDER "must use --force flag to overwrite"
				return 2
				;;
		esac
	}

	STATUS "creating iamserviceaccount" \
		&& EKSCTL create iamserviceaccount \
			--cluster $CLUSTER_NAME \
			--namespace $NAMESPACE \
			--name $SERVICEACCOUNT \
			--role-name $ROLE_NAME \
			--override-existing-serviceaccounts \
			--approve \
			${EKSCTL_ARGS[@]} \
		&& SUCCESS "successfully configured '$NAMESPACE/$SERVICEACCOUNT' with IAM role '$ROLE_NAME'" \
		|| { ERROR "unable to configure '$NAMESPACE/$SERVICEACCOUNT' with IAM role '$ROLE_NAME' (check cloudformation dashboard for details)"; return 3; }
}

_EKS__CHECK_IAMSERVICEACCOUNT_EXISTS() {
	STATUS "checking for existing role-arn"
	local CURRENT_ROLE_ARN=$(
		EKS__KUBECTL --namespace $NAMESPACE get serviceaccount $SERVICEACCOUNT -o yaml \
			| YQ -r '.metadata.annotations["eks.amazonaws.com/role-arn"]' \
			| grep -v '^null$' \
	)

	[ $CURRENT_ROLE_ARN ] || {
		STATUS "serviceaccount does not exist or has no configured role"
		return 1
	}

	[[ $CURRENT_ROLE_ARN =~ "$ROLE_NAME$" ]] || {
		STATUS "serviceaccount current role does not match desired role:
			  CURRENT : $CURRENT_ROLE_ARN
			  DESIRED : arn:aws:iam::${AWS_ACCOUNT}:role/$ROLE_NAME
			  "
		return 2
	}

	STATUS "serviceaccount current role matches desired role"
	return 0
}
