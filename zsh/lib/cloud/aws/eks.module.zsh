#####################################################################

DEPENDENCIES+=(
	kubectl
)

REQUIRED_ENV+=(
	AWS_ACCOUNT
	AWS_REGION
)

use cloud/aws/cli

#####################################################################

EKS_CLUSTER_LOGIN() {
	local USAGE="
		usage:  [...options...]

		options
		  -c, --cluster-name <string>   (optional) login a specific cluster


		Interactively sets the default kubeconfig to match the selected
		cluster in EKS. Also creates the kubeconfig entry if it does not
		already exist.
	"

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
