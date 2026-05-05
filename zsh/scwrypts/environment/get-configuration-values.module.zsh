#####################################################################

use scwrypts/environment/get-enriched-user-yaml

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		returns json which contains shell-compatible lookup values
		  - moves inherited .PARENTVALUE to value (if value is empty)
		  - moves inherited .PARENTSELECTION to selection (if selection is empty)
	"

	local PARSERS=(scwrypts.zshparse.environment-name)

	eval "$(utils.parse.autosetup)"

	##########################################

	scwrypts.environment.get-enriched-user-yaml "${@}" \
		| utils.yq '..
			|= select(
				((has ("value") | not) or .value == null or .value | length == 0) and has (".PARENTVALUE")
				).value = .".PARENTVALUE"
			' \
		| utils.yq '..
			|= select(
				((has ("selection") | not) or .selection == null or .selection | length == 0) and has (".PARENTSELECTION")
				).selection = .".PARENTSELECTION"
			' \
		| utils.yq '.
			| del(.. | select(has(".PARENTVALUE")).".PARENTVALUE")
			| del(.. | select(has(".PARENTSELECTION")).".PARENTSELECTION")
			| del(.. | select(has(".GROUP")).".GROUP")
			| del(.. | select(has(".DESCRIPTION")).".DESCRIPTION")
			| del(.. | select(has("value") and (.value == null or .value | length == 0)).value)
			| del(.. | select(has("selection") and (.selection == null or .selection | length == 0)).selection)
			| del(.. | select(has("value") and has("selection")).selection)
			' \
			;
}
