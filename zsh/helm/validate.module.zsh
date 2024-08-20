#####################################################################

DEPENDENCIES+=(yq)
REQUIRED_ENV+=()

#####################################################################

HELM__VALIDATE() {
	[ ! $USAGE ] && USAGE="
		usage:

		environment
		  TEMPLATE_FILENAME   target template filename

		Smart helm-detection / validator which determines the helm
		chart root and other details given a particular filename.
	"

	[ $TEMPLATE_FILENAME ] && [ -f "$TEMPLATE_FILENAME" ] || {
		echo.error 'must provide a template filename'
		return 1
	}

	_HELM__GET_CHART_ROOT
	[ $CHART_ROOT ] && [ -d "$CHART_ROOT" ] || {
		echo.error 'unable to determine helm root; is this a helm template file?'
		return 1
	}

	CHART_NAME=$(utils.yq -r .name "$CHART_ROOT/Chart.yaml")

	[[ $TEMPLATE_FILENAME =~ values.*.yaml$ ]] && {
		HELM_ARGS+=(--values $TEMPLATE_FILENAME)
		USE_CHART_ROOT=1
	}

	[[ $TEMPLATE_FILENAME =~ tests/.*.yaml$ ]] && {
		HELM_ARGS+=(--values $TEMPLATE_FILENAME)
		USE_CHART_ROOT=1
	}
	[[ $TEMPLATE_FILENAME =~ .tpl$ ]] \
		&& USE_CHART_ROOT=1

	[[ $(dirname $TEMPLATE_FILENAME) =~ ^$CHART_ROOT$ ]] \
		&& USE_CHART_ROOT=1

	_HELM__GET_DEFAULT_VALUES_ARGS

	return 0
}

_HELM__GET_CHART_ROOT() {
	local SEARCH_DIR=$(dirname "$TEMPLATE_FILENAME")
	while [ ! $CHART_ROOT ] && [[ ! $SEARCH_DIR =~ ^/$ ]]
	do
		[ -f "$SEARCH_DIR/Chart.yaml" ] && CHART_ROOT="$SEARCH_DIR" && return 0
		SEARCH_DIR="$(dirname "$SEARCH_DIR")"
	done

	return 1
}

_HELM__GET_DEFAULT_VALUES_ARGS() {
	for F in \
		"$CHART_ROOT/tests/default.yaml" \
		"$CHART_ROOT/values.test.yaml" \
		"$CHART_ROOT/values.yaml" \
		;
	do
		[ -f "$F" ] && HELM_ARGS=(--values "$F" $HELM_ARGS)
	done

	for LOCAL_REPOSITORY in $(\
		cat "$CHART_ROOT/Chart.yaml" \
			| utils.yq -r '.dependencies[] | .repository' \
			| grep '^file://' \
			| sed 's|file://||' \
		)
	do
		[[ $LOCAL_REPOSITORY =~ ^[/~] ]] \
			&& LOCAL_REPOSITORY_ROOT="$LOCAL_REPOSITORY" \
			|| LOCAL_REPOSITORY_ROOT="$CHART_ROOT/$LOCAL_REPOSITORY" \
			;

		for F in \
			"$LOCAL_REPOSITORY_ROOT/tests/default.yaml" \
			"$LOCAL_REPOSITORY_ROOT/values.test.yaml" \
			"$LOCAL_REPOSITORY_ROOT/values.yaml" \
			;
		do
			[ -f "$F" ] && HELM_ARGS=(--values "$F" $HELM_ARGS)
		done
	done
}

