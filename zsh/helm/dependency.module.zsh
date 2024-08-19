#####################################################################

DEPENDENCIES+=(helm kubeval)
REQUIRED_ENV+=()

use helm/validate

#####################################################################

HELM__DEPENDENCY__UPDATE() {
	[ ! $USAGE ] && local USAGE="
		usage: [...options...]

		options
		  -t, --template-filename   path to a template/*.yaml file of a helm chart

		Auto-detect chart and build dependencies for any file within a helm chart.
	"
	local TEMPLATE_FILENAME CHART_ROOT VALUES_FILES=()
	local COLORIZE=0 RAW=0 DEBUG=0

	while [[ $# -gt 0 ]]
	do
		case $1 in 
			-t | --template-filename ) TEMPLATE_FILENAME="$(SCWRYPTS__GET_REALPATH "$2")"; shift 1 ;;

			* ) echo.error "unexpected argument '$1'" ;;
		esac
		shift 1
	done

	HELM__VALIDATE
	CHECK_ERRORS || return 1

	##########################################

	echo.status "updating helm dependencies for '$CHART_ROOT'" \
		&& cd $CHART_ROOT  \
		&& helm dependency update \
		&& echo.success "helm chart dependencies updated" \
		|| { echo.error "unable to update helm chart dependencies (see above)"; return 1; }
}
