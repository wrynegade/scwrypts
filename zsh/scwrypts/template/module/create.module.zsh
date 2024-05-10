#####################################################################

use scwrypts/template/zshparse

#####################################################################

${scwryptsmodule}() {
	local TEMPLATE_FILE="$(scwrypts.config.group scwrypts root)/zsh/scwrypts/template/module/template.zsh"
	local PARSERS=(
		scwrypts.template.zshparse.include-help
		scwrypts.template.zshparse.mode-select
		)

	eval "$(utils.parse.autosetup)"
	##########################################

	case ${TEMPLATE_GENERATION_MODE} in
		( stdout )
			echo "${TEMPLATE}"
			;;
	esac
}

#####################################################################

${scwryptsmodule}.parse() { return 0; }

${scwryptsmodule}.parse.usage() {
	USAGE__description='
		sets up recommended boilerplate for a new scwrypts module
	'
}
