#####################################################################

use scwrypts/environment/common

use zsh-cache

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		Provies the combined YAML of all available scwrypts group 'template.yaml' files.

		Template is cached after first generation in a given scwrypts runtime.
	"

	eval "$(utils.parse.autosetup)"

	##########################################

	zsh-cache --auto
}

${scwryptsmodule}.zsh-cache() {
	local DEBUG_ARGS=() TRACE_ARGS=()
	local template_file group _
	while IFS=: read -r group template_file _
	do
		[[ "$(head -n1 "${template_file}")" =~ ^---$ ]] || echo ---

		cat -- "${template_file}" \
			| utils.yq "(.. | select(has(\".ENVIRONMENT\"))) += {\".GROUP\":\"${group}\"}"
	done < <(scwrypts.environment.common.get-all-template-files) \
		| scwrypts.environment.common.combine-template-files

	return 0
}

${scwryptsmodule}.zsh-cache.get-hash() {
	{
		scwrypts.environment.common.get-environment-module-files
		scwrypts.environment.common.get-all-template-files.only-filenames
	} | utils.sha1sum.filelist
}

${scwryptsmodule}.with-value-keys() {
	scwrypts.environment.get-full-template \
		| utils.yq '(.. | select(has(".ENVIRONMENT"))) += {
				"selection": [],
				"value": null
			}
			' \
		| sed 's/ ""$//' \
		;
}
