#####################################################################

DEPENDENCIES+=(kubectl yq)
REQUIRED_ENV+=()

use cloud/aws/cli

#####################################################################

EKS__KUBECTL() { EKS kubectl $@; }
EKS__FLUX()    { EKS flux $@; }

#####################################################################

EKS() {
	local USAGE="
		usage: cli [...kubectl args...]

		args:
		  cli   a kubectl-style CLI (e.g. kubectl, helm, flux, etc)

		Allows access to kubernetes CLI commands by configuring environment
		to point to a specific cluster.
	"

	REQUIRED_ENV=(AWS_REGION AWS_ACCOUNT CLUSTER_NAME) DEPENDENCIES=(kubectl $1) CHECK_ENVIRONMENT || return 1

	local CONTEXT="arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT}:cluster/${CLUSTER_NAME}"

	local CONTEXT_ARGS=()
	case $1 in
		helm ) CONTEXT_ARGS+=(--kube-context $CONTEXT) ;;
		* ) CONTEXT_ARGS+=(--context $CONTEXT) ;;
	esac

	$1 ${CONTEXT_ARGS[@]} ${@:2}
}

#####################################################################

EKS__CLUSTER_LOGIN() {
	local USAGE="
		usage:  [...options...]

		options
		  -c, --cluster-name <string>   (optional) login a specific cluster


		Interactively sets the default kubeconfig to match the selected
		cluster in EKS. Also creates the kubeconfig entry if it does not
		already exist.
	"
	REQUIRED_ENV=(AWS_ACCOUNT AWS_REGION) CHECK_ENVIRONMENT || return 1

	local CLUSTER_NAME

	while [[ $# -gt 0 ]]
	do
		case $1 in 
			-c | --cluster-name ) CLUSTER_NAME="$2"; shift 1 ;;

			* ) [ ! $APPLICATION  ] && APPLICATION="$1" \
					|| ERROR "extra positional argument '$1'"
				;;
		esac
		shift 1
	done

	[ ! $CLUSTER_NAME ] && CLUSTER_NAME=$(\
		AWS eks list-clusters \
			| jq -r '.[] | .[]' \
			| FZF 'select a cluster'
	)

	[ ! $CLUSTER_NAME ] && ERROR 'must select a valid cluster or use -c flag'

	CHECK_ERRORS

	##########################################

	STATUS 'creating / updating kubeconfig for EKS cluster'
	STATUS "updating kubeconfig for '$CLUSTER_NAME'"
	AWS eks update-kubeconfig --name $CLUSTER_NAME \
		&& SUCCESS "kubeconfig updated with '$CLUSTER_NAME'" \
		|| ERROR "failed to update kubeconfig; do you have permissions to access '$CLUSTER_NAME'?"
}
