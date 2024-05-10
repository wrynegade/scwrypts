#####################################################################

use scwrypts/get-realpath

use helm/zshparse

DEPENDENCIES+=(helm)

#####################################################################

${scwryptsmodule}() {
	local PARSERS=(helm.zshparse)
	eval "$(utils.parse.autosetup)"

	##########################################

	local HELM_LINT_ARGS=(${HELM_ARGS[@]})

	[[ ${USE_CHART_ROOT} =~ false ]] \
		&& HELM_ARGS+=(--show-only "$(echo "${TEMPLATE_FILENAME}" | sed "s|^${CHART_ROOT}/||")")

	local TEMPLATE_OUTPUT DEBUG_OUTPUT
	utils.io.capture TEMPLATE_OUTPUT DEBUG_OUTPUT \
		helm template "${CHART_ROOT}" ${HELM_ARGS[@]} --debug \
		;

	local EXIT_CODE
	[ "${TEMPLATE_OUTPUT}" ] && EXIT_CODE=0 || EXIT_CODE=1

	case ${OUTPUT_MODE} in
		( raw )
			[[ ${EXIT_CODE} -eq 0 ]] \
				&& echo "${TEMPLATE_OUTPUT}" | grep -v '^# Source:.*$' \
				|| echo "${DEBUG_OUTPUT}" >&2 \
				;
			;;

		( color )
			[[ ${EXIT_CODE} -eq 0 ]] \
				&& echo "${TEMPLATE_OUTPUT}" | bat --language yaml --color always \
				|| echo "${DEBUG_OUTPUT}" >&2 \
				;
			;;

		( debug )
			[[ ${EXIT_CODE} -eq 0 ]] \
				&& KUBEVAL_RAW=$(
					echo "${TEMPLATE_OUTPUT}" \
						| kubeval --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master \
					) \
				|| KUBEVAL_RAW='no template output; kubeval skipped'

			echo "
				${TEMPLATE_OUTPUT}
				---
				debug: |\n$(echo ${DEBUG_OUTPUT} | sed 's/^/  /g')

				kubeval: |\n$(echo ${KUBEVAL_RAW} | sed 's/^/  /g')

				lint: |\n$(helm lint "${CHART_ROOT}" ${HELM_LINT_ARGS[@]} 2>&1 | sed 's/^/  /g')
				" | sed 's/^	\+//; 1d; $d'
			;;
	esac

	return ${EXIT_CODE}
}

#####################################################################

${scwryptsmodule}.parse() {
	local PARSED=0

	case $1 in
		( --colorize ) PARSED=1; OUTPUT_MODE=color ;;
		( --raw      ) PARSED=1; OUTPUT_MODE=raw ;;
		( --debug    ) PARSED=1; OUTPUT_MODE=debug ;;

		( --update   ) PARSED=1; UPDATE_DEPENDENCIES=true ;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.parse.locals() {
	local OUTPUT_MODE=default
	local UPDATE_DEPENDENCIES=false
}

${scwryptsmodule}.parse.usage() {
	USAGE__description="
		Smart helm-template generator which auto-detects the chart
		and sample values for testing and developing helm charts.
	"

	local DEFAULT
	utils.dependencies.check bat &>/dev/null \
		&& DEFAULT=color || DEFAULT=raw

	USAGE__options+="
		--colorize   $([[ ${DEFAULT} =~ color ]] && printf '(default) ')use 'bat' to colorize output
		--raw        $([[ ${DEFAULT} =~ raw   ]] && printf '(default) ')remove scwrypts-added fluff and only output helm template details
		--debug      debug template with kubeval and helm-lint

		--update   update dependencies before generating template output
	"
}

${scwryptsmodule}.parse.validate() {
	case ${OUTPUT_MODE} in
		( default )
			utils.dependencies.check bat &>/dev/null \
				&& OUTPUT_MODE=color \
				|| OUTPUT_MODE=raw \
				;
			;;

		( color )
			utils.dependencies.check bat || ((ERRORS+=1))
			;;

		( debug )
			utils.dependencies.check kubeval \
				|| echo.error 'kubeval is required for --debug'
			;;
	esac

	case ${UPDATE_DEPENDENCIES} in
		( false ) ;;
		( true )
			use helm/update-dependencies
			helm.update-dependencies --template-filename "${TEMPLATE_FILENAME}" &>/dev/null \
				|| echo.error 'failed to update dependencies'
			;;
	esac
}
