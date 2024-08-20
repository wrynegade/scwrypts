ARGS_PARSER__EKSCTL__CREATE_IAMSERVICEACCOUNT() {
	# local SERVICEACCOUNT NAMESPACE ROLE_NAME
	# local FORCE=false                          whether or not to force a new eksctl deployment

	local PARSED=0

	case $1 in
		--serviceaccount ) PARSED=2; SERVICEACCOUNT=$2 ;;
		--namespace      ) PARSED=2; NAMESPACE=$2 ;;
		--role-name      ) PARSED=2; ROLE_NAME=$2 ;;

		--force ) PARSED=1; FORCE=true ;;
	esac

	return $PARSED
}

ARGS_PARSER__EKSCTL__CREATE_IAMSERVICEACCOUNT.usage() {
	[[ $USAGE__usage =~ 'options' ]] || USAGE__usage+=' [...options...]'
	USAGE__options+="\n
		--serviceaccount   (required) target k8s:ServiceAccount
		--namespace        (required) target k8s:Namespace
		--role-name        (required) name of the IAM role to assign

		--force   don't check for existing serviceaccount and override any existing configuration
	"
}

ARGS_PARSER__EKSCTL__CREATE_IAMSERVICEACCOUNT.validate() {
	[ $SERVICEACCOUNT ] || echo.error "--serviceaccount is required"
	[ $NAMESPACE      ] || echo.error "--namespace is required"
	[ $ROLE_NAME      ] || echo.error "--role-name is required"
}
