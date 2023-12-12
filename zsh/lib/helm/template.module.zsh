#####################################################################

DEPENDENCIES+=(helm kubeval)
REQUIRED_ENV+=()

use helm/validate
use scwrypts

#####################################################################

HELM__TEMPLATE__GET() {
	[ ! $USAGE ] && local USAGE="
		usage: [...options...] (--) [...helm args...]

		options
		  -t, --template-filename   path to a template/*.yaml file of a helm chart

		  --colorize   use 'bat' to colorize output
		  --raw        remove scwrypts-added fluff and only output helm template details

		  -h, --help   show this help dialogue

		Smart helm-template generator which auto-detects the chart
		and sample values for testing and developing helm charts.
	"
	local HELM_ARGS=()
	local TEMPLATE_FILENAME TEMPLATE_NAME CHART_ROOT CHART_NAME VALUES_FILES=()
	local COLORIZE=0 RAW=0 DEBUG=0

	while [[ $# -gt 0 ]]
	do
		case $1 in 
			-t | --template-filename ) TEMPLATE_FILENAME="$(SCWRYPTS__GET_REALPATH "$2")"; shift 1 ;;

			--colorize )
				DEPENDENCIES=(bat) CHECK_ENVIRONMENT || return 1
				COLORIZE=1
				;;

			--raw ) RAW=1 ;;

			-h | --help ) USAGE; return 0 ;;
			-- ) shift 1; break ;;


			* ) HELM_ARGS+=($1) ;;
		esac
		shift 1
	done

	while [[ $# -gt 0 ]]; do HELM_ARGS+=($1); shift 1; done

	HELM__VALIDATE
	CHECK_ERRORS || return 1

	##########################################

	local EXIT_CODE=0
	local TEMPLATE_OUTPUT DEBUG_OUTPUT
	[ $USE_CHART_ROOT ] && [[ $USE_CHART_ROOT -eq 1 ]] && {
		CAPTURE TEMPLATE_OUTPUT DEBUG_OUTPUT helm template "$CHART_ROOT" ${HELM_ARGS[@]} --debug
		true
	} || {
		CAPTURE TEMPLATE_OUTPUT DEBUG_OUTPUT helm template "$CHART_ROOT" ${HELM_ARGS[@]} --debug --show-only "$(echo $TEMPLATE_FILENAME | sed "s|^$CHART_ROOT/||")"
	}
		
	[ ! $TEMPLATE_OUTPUT ] && EXIT_CODE=1


	[[ $RAW -eq 1 ]] && {
		[ $USE_CHART_ROOT ] && [[ $USE_CHART_ROOT -eq 1 ]] || HELM_ARGS+=(--show-only $(echo $TEMPLATE_FILENAME | sed "s|^$CHART_ROOT/||"))
		[[ $COLORIZE -eq 1 ]] \
			&& helm template "$CHART_ROOT" ${HELM_ARGS[@]} 2>&1 | bat --language yaml --color always \
			|| helm template "$CHART_ROOT" ${HELM_ARGS[@]} | grep -v '^# Source:.*$' \
			;

		return $EXIT_CODE
	}

	[ $TEMPLATE_OUTPUT ] && {
		KUBEVAL_RAW=$(echo $TEMPLATE_OUTPUT | kubeval --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master)
		true
	} || {
		TEMPLATE_OUTPUT="---\nerror: chart or '$(basename $(dirname $TEMPLATE_FILENAME))/$(basename $TEMPLATE_FILENAME)' invalid"
		KUBEVAL_RAW="no template output; kubeval skipped"

		[ $USE_CHART_ROOT ] && [[ $USE_CHART_ROOT -eq 1 ]] || {
			DEBUG_OUTPUT="$(helm template "$CHART_ROOT" ${HELM_ARGS[@]} --debug 2>&1 >/dev/null)"
		}
	}

	TEMPLATE_OUTPUT="$TEMPLATE_OUTPUT
---
debug: |
$(echo $DEBUG_OUTPUT | sed 's/^/  /g')

kubeval: |
$(echo $KUBEVAL_RAW | sed 's/^/  /g')

lint: |
$(helm lint $CHART_ROOT ${HELM_ARGS[@]} 2>&1 | sed 's/^/  /g')
"

	[[ $COLORIZE -eq 1 ]] && {
		echo $TEMPLATE_OUTPUT | bat --language yaml --color always
	} || {
		echo $TEMPLATE_OUTPUT
	}

	return $EXIT_CODE
}
