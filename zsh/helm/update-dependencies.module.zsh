#####################################################################

use helm/zshparse

DEPENDENCIES+=(helm)

#####################################################################

${scwryptsmodule}() {
	local PARSERS=(helm.zshparse)

	eval "$(utils.parse.autosetup)"

	##########################################

	echo.status "updating helm dependencies for '${CHART_ROOT}'" \

	helm dependency update "${CHART_ROOT}" \
		&& echo.success "helm chart dependencies updated" \
		|| echo.error   "unable to update helm chart dependencies (see above)" \
		|| return 1
}

#####################################################################

${scwryptsmodule}.parse() { return 0; }
${scwryptsmodule}.parse.usage() {
	USAGE__description='
		Auto-detect chart and build dependencies for any file within a helm chart.
	'
}
