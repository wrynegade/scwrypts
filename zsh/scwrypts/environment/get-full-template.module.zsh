#####################################################################

use scwrypts/cache-output
use scwrypts/environment/common

#####################################################################

${scwryptsmodule}() {
	eval "$(usage.reset)"
	local USAGE__description="
		Provies the combined YAML of all available scwrypts group 'template.yaml' files.

		Template is cached after first generation in a given scwrypts runtime.
	"

	local \
		CACHE_ARGS=() \
		PARSERS=(
			scwrypts.cache-output.zshparse.args
			)

	eval "$ZSHPARSEARGS"
	##########################################

	scwrypts.cache-output ${CACHE_ARGS[@]} \
		--cache-file environment.template.yaml \
		-- \
		scwrypts.environment.get-full-template.helper \
		;
}

${scwryptsmodule}.helper() {
	local GROUP GROUP_ROOT GROUP_TEMPLATE_FILENAME
	{
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		GROUP_ROOT="$(scwrypts.config.group ${GROUP} root)"

		GROUP_TEMPLATE_FILENAME="${GROUP_ROOT}/.config/env.yaml"

		[ -f "${GROUP_TEMPLATE_FILENAME}" ] && {
			[[ $(head -n1 "${GROUP_TEMPLATE_FILENAME}") =~ ^---$ ]] || echo ---
				cat "${GROUP_TEMPLATE_FILENAME}" \
					| utils.yq "(.. | select(has(\".ENVIRONMENT\"))) += {\".GROUP\":\"${GROUP}\"}"
		}
	done
	} | scwrypts.environment.common.combine-template-files
}
