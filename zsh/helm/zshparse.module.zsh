#####################################################################

use helm/validate
use scwrypts/get-realpath

#####################################################################

${scwryptsmodule}() {
	local PARSED=0

	case $1 in
		( -t | --template-filename )
			PARSED=2
			TEMPLATE_FILENAME="$(scwrypts.get-realpath "$2")"
			;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.locals() {
	local TEMPLATE_FILENAME
	local ARGS=()

	# configured by helm.validate
	local CHART_NAME
	local CHART_ROOT
	local HELM_ARGS=()
}

${scwryptsmodule}.usage() {
	USAGE__options+='
		-t, --template-filename   path to a template/*.yaml file of a helm chart
	'

	USAGE__args+='
		\$@   additional args are forwarded to helm
	'
}

${scwryptsmodule}.validate() {
	helm.validate || return 1

	HELM_ARGS+=(${ARGS[@]})

	echo.debug "
		template filename : ${TEMPLATE_FILENAME}
		chart name        : ${CHART_NAME}
		chart root        : ${CHART_ROOT}
		helm args         : ${HELM_ARGS[@]}
	"
}

#####################################################################
