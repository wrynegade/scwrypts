#####################################################################

DEPENDENCIES+=(yq)
REQUIRED_ENV+=()

#####################################################################

${scwryptsmodule}() {
	local USAGE="
		Smart helm-detection / validator which determines the helm
		chart root and other details given a particular filename.

		You must set TEMPLATE_FILENAME, and this function will verify
		the template is part of a helm chart and set up the following
		variables:

		  - CHART_ROOT : the fully qualified path to the directory
		                 containing Chart.yaml

		  - CHART_NAME : Chart.yaml > .name

		  - USE_CHART_ROOT (true/false)
		         true  : operations should use/output the entire chart
			     false : operations should use/output a single template

		  - HELM_ARGS  : an array of arguments which apply to any 'helm'
		                 command
	"

	[ "${TEMPLATE_FILENAME}" ] && [ -f "${TEMPLATE_FILENAME}" ] \
		|| echo.error 'must provide a template filename' \
		|| return 1

	##########################################

	CHART_ROOT="$(helm.validate.get-chart-root)"
	[ ${CHART_ROOT} ] && [ -d "${CHART_ROOT}" ] \
		|| echo.error 'unable to determine helm root; is this a helm template file?' \
		|| return 1

	##########################################

	CHART_NAME=$(utils.yq -r .name "${CHART_ROOT}/Chart.yaml")

	##########################################

	USE_CHART_ROOT=false

	case "${TEMPLATE_FILENAME}" in
		( *values.*.yaml | *tests/*.yaml )
			HELM_ARGS+=(--values ${TEMPLATE_FILENAME})
			USE_CHART_ROOT=true
			;;

		( *.tpl )
			USE_CHART_ROOT=true
			;;
	esac

	[[ $(dirname -- "${TEMPLATE_FILENAME}") =~ ^${CHART_ROOT}$ ]] \
		&& USE_CHART_ROOT=true

	##########################################

	HELM_ARGS=($(helm.validate.get-default-values-args) ${HELM_ARGS[@]})

	##########################################

	return 0
}

${scwryptsmodule}.get-chart-root() {
	local SEARCH_DIR=$(dirname -- "${TEMPLATE_FILENAME}")
	while [[ ! ${SEARCH_DIR} =~ ^/$ ]]
	do
		[ -f "${SEARCH_DIR}/Chart.yaml" ] \
			&& echo "${SEARCH_DIR}" \
			&& return 0 \
			;

		SEARCH_DIR="$(dirname -- "${SEARCH_DIR}")"
	done
	return 1
}

${scwryptsmodule}.get-default-values-args() {
	local F
	local VALUES_FILES_ORDER=(
		values.yaml         # the default values of the chart
		tests/default.yaml  # a template test which provides any required values not included in the default values
	)

	local LOCAL_DEPENDENCY_CHART LOCAL_CHART_ROOT
	for LOCAL_DEPENDENCY_CHART in $(\
		cat "${CHART_ROOT}/Chart.yaml" \
			| utils.yq -r '.dependencies[] | .repository' \
			| grep '^file://' \
			| sed 's|file://||' \
		)
	do
		[[ "${LOCAL_DEPENDENCY_CHART}" =~ ^[/~] ]] \
			&& LOCAL_CHART_ROOT="${LOCAL_DEPENDENCY_CHART}" \
			|| LOCAL_CHART_ROOT=$(readlink -f -- "${CHART_ROOT}/${LOCAL_DEPENDENCY_CHART}") \
			;

		for F in ${VALUES_FILES_ORDER[@]}
		do
			[ -f "${LOCAL_CHART_ROOT}/${F}" ] \
				&& echo --values "${LOCAL_CHART_ROOT}/${F}"
		done
	done

	local HELM_VALUES_ARGS=()
	for F in ${VALUES_FILES_ORDER[@]}
	do
		[ -f "${CHART_ROOT}/${F}" ] \
			&& echo --values "${CHART_ROOT}/${F}"
	done
}
