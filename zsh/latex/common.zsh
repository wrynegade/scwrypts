_DEPENDENCIES+=(
	rg
)
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

GET_MAIN_LATEX_FILENAME() {
	local FILENAME=$(__GET_PATH_TO_RELATIVE_ARGUMENT "$1")
	local DIRNAME="$FILENAME"

	for _ in {1..3}
	do
		CHECK_IS_MAIN_LATEX_FILE && return 0
		DIRNAME="$(dirname "$FILENAME")"
		__STATUS "checking '$DIRNAME'"
		[[ $DIRNAME =~ ^$HOME$ ]] && break
		FILENAME=$(
			rg -l --max-depth 1 'documentclass' "$DIRNAME/" \
				| grep '\.tex$' \
				| head -n1 \
		)
		__STATUS "here is '$FILENAME'"
	done

	__WARNING 'unable to find documentclass; pdflatex will probably fail'
	echo "$1"
}

CHECK_IS_MAIN_LATEX_FILE() {
	[ ! $FILENAME ] && return 1
	grep -q 'documentclass' $FILENAME 2>/dev/null && echo $FILENAME || return 3
}

