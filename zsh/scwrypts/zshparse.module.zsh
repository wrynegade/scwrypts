${scwryptsmodule}.environment-name.locals() {
	local environment_name="${SCWRYPTS_ENV}"
}

${scwryptsmodule}.environment-name() {
	local p=0

	case "${1}" in
		( --environment-name ) p=2; environment_name="${2}" ;;
	esac

	return ${p}
}

${scwryptsmodule}.environment-name.usage() {
	USAGE__options+="\n
		--environment-name <string>   name of a scwrypts environment; when unspecified, uses current
		                              (current: ${SCWRYPTS_ENV})
	"
}
