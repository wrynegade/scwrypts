#####################################################################

use cloud/aws/eksctl/cli
use cloud/aws/eksctl/iamserviceaccount/check-exists

use cloud/aws/eksctl/iamserviceaccount/zshparse
use cloud/aws/zshparse/overrides
use cloud/aws/eks/zshparse/cluster-name

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		creates an 'iamserviceaccount' which provides a Kubernetes
		serviceaccount with AWS role identity and access control
	"

	local PARSERS=(
		cloud.aws.eksctl.iamserviceaccount.zshparse
		cloud.aws.zshparse.overrides
		cloud.aws.eks.zshparse.cluster-name
	)

	eval "$(utils.parse.autosetup)"

	##########################################

	case ${FORCE} in
		( true ) ;;
		( false )
			cloud.aws.eksctl.iamserviceaccount.check-exists \
				--serviceaccount "${SERVICEACCOUNT}" \
				--namespace      "${NAMESPACE}" \
				--role-name      "${ROLE_NAME}" \
				${AWS_PASSTHROUGH[@]} \
				;
			case $? in
				(   0 ) echo.success "'${NAMESPACE}/${SERVICEACCOUNT}' already configured with '${ROLE_NAME}'"
					return 0
					;;
				( 100 ) # role does not exist yet; continue with rollout
					;;
				( 200 ) echo.error "'${NAMESPACE}/${SERVICEACCOUNT}' has been configured with a different role than '${ROLE_NAME}'"
					echo.reminder "must use --force flag to overwrite"
					return 2
					;;
			esac
			;;
	esac

	echo.status "creating iamserviceaccount" \
		&& cloud.aws.eksctl.cli ${AWS_PASSTHROUGH_ARGS[@]} create iamserviceaccount \
			--cluster   "${CLUSTER_NAME}" \
			--namespace "${NAMESPACE}" \
			--name      "${SERVICEACCOUNT}" \
			--role-name "${ROLE_NAME}" \
			--override-existing-serviceaccounts \
			--approve \
			${ARGS[@]} \
		&& echo.success "successfully configured '${NAMESPACE}/${SERVICEACCOUNT}' with IAM role '${ROLE_NAME}'" \
		|| echo.error   "unable to configure '${NAMESPACE}/${SERVICEACCOUNT}' with IAM role '${ROLE_NAME}'\n(check cloudformation dashboard for details)" \
		;
}

#####################################################################

${scwryptsmodule}.parse.locals() {
	local FORCE=false   # whether or not to force a new eksctl deployment
	local ARGS=()
}

${scwryptsmodule}.parse() {
	local PARSED=0

	case $1 in
		--force ) PARSED=1; FORCE=true ;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.parse.usage() {
	USAGE__options+="
		--force   don't check for existing serviceaccount and override any existing configuration
	"

	USAGE__args+="
		args   all remaining arguments are forwarded to 'eksctl create iamserviceaccount'

		eksctl create iamserviceaccount args:
		$(eksctl create iamserviceaccount --help 2>&1 | grep -v -- '--name' | grep -v -- '--namespace' | grep -v -- '--role-name' | sed 's/^/  /')
	"
}
