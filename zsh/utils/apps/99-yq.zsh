yq --version | grep -q mikefarah && {
	utils.yq() { yq eval '... comments=""' | yq "${@}"; }
} || {
	echo.warning '
	The utils.yq helper expects mikefarah/yq, but you appear to have kislyuk/yq or another flavor.
	Compatibility may vary.
	'

	utils.yq() { yq "${@}"; }
}

utils.yq.combine-files() { utils.yq \
	| utils.yq eval-all '. as $item ireduce ({}; . * $item)' \
	| utils.yq 'sort_keys(..)' \
; }
