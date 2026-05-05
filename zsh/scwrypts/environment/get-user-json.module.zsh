#####################################################################

use scwrypts/environment/common
use scwrypts/environment/get-configuration-values
use scwrypts/environment/get-envvar-lookup-map
use scwrypts/environment/get-full-template

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		returns the fully populated configuration object for the target
		environment; this should be used as the primary source of truth
		for scwrypts environment configuration

		values must be retrieved from '.configuration' by their lookup key

		for values with a configured environment variable, the lookup key
		can be found in '.lookup.ENVIRONMENT_VARIABLE'

		\`\`\`yaml
		someGroup:
		  myData:
		    value: abcdefg 1234
		    .ENVIRONMENT: MY_DATA_VARIABLE
		\`\`\`

		utils.yq .lookup.MY_DATA_VARIABLE              > '.someGroup.myData'
		utils.yq .configuration.someGroup.myData.value > 'abcdefgh 1234'
	"

	local PARSERS=(scwrypts.zshparse.environment-name)

	eval "$(utils.parse.autosetup)"

	##########################################

	zsh-cache --auto -- --environment-name "${environment_name}"
}

${scwryptsmodule}.zsh-cache.get-hash() {
	local PARSERS=(scwrypts.zshparse.environment-name)
	eval "$(utils.parse.autosetup)"
	{
		scwrypts.environment.common.get-environment-module-files
		scwrypts.environment.common.get-all-template-files.only-filenames
		scwrypts.environment.common.get-all-configuration-files --environment-name "${environment_name}"
	} | utils.sha1sum.filelist
}

${scwryptsmodule}.zsh-cache() {
	local PARSERS=(scwrypts.zshparse.environment-name)
	eval "$(utils.parse.autosetup)"
	##########################################
	local configuration="$(scwrypts.environment.get-configuration-values --environment-name "${environment_name}")"
	local lookup_map="$(scwrypts.environment.get-envvar-lookup-map)"

	echo.trace 'generating user json' -v lookup_map
	{
		echo "configuration:"
		echo "${configuration}" | sed 's/^/  /'

		echo "lookup:"
		echo "${lookup_map}" | sed 's/^/  /'
	} | utils.yq -oj | jq -c
}
