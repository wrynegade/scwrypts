#####################################################################

${scwryptsmodule}.locals() {
	local SERVICEACCOUNT
	local NAMESPACE
	local ROLE_NAME
}

${scwryptsmodule}() {
	local PARSED=0

	case $1 in
		--serviceaccount ) PARSED=2; SERVICEACCOUNT=$2 ;;
		--namespace      ) PARSED=2; NAMESPACE=$2 ;;
		--role-name      ) PARSED=2; ROLE_NAME=$2 ;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.usage() {
	USAGE__options+="
		--serviceaccount   (required) target k8s:ServiceAccount
		--namespace        (required) target k8s:Namespace
		--role-name        (required) name of the IAM role to assign
	"
}

${scwryptsmodule}.validate() {
	[ "${SERVICEACCOUNT}" ] || echo.error "--serviceaccount is required"
	[ "${NAMESPACE}"      ] || echo.error "--namespace is required"
	[ "${ROLE_NAME}"      ] || echo.error "--role-name is required"
}

#####################################################################
