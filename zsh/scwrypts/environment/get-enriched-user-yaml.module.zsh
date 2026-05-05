#####################################################################

use scwrypts/environment/common
use scwrypts/zshparse

use zsh-cache

#####################################################################

${scwryptsmodule}() {
	local DESCRIPTION="
		Generates a metadata-enriched scwrypts environment YAML.
	"
	local PARSERS=(scwrypts.zshparse.environment-name)

	eval "$(utils.parse.autosetup)"

	##########################################

	zsh-cache --auto -- "${environment_name}"
}

${scwryptsmodule}.zsh-cache.get-hash() {
	local environment_name="${1:-${SCWRYPTS_ENV}}"
	{
		scwrypts.environment.common.get-environment-module-files
		scwrypts.environment.common.get-all-template-files.only-filenames
		scwrypts.environment.common.get-all-configuration-files --environment-name "${environment_name}"
	} | utils.sha1sum.filelist
}

${scwryptsmodule}.zsh-cache() {
	local ERRORS=0 WARNINGS=0

	local environment_name="${SCWRYPTS_ENV}"
	local loading_original_env=true

	local _s _p
	while [[ "${#}" -gt 0 ]]
	do
		_s=1
		case "${1}" in
			( --parent ) loading_original_env=false ;;
			( * )
				case "$((_p+=1))" in
					( 1 ) environment_name="${1}" ;;
					( * ) echo.error "unknown argument '${1}'" ;;
				esac
		esac
		shift "${_s}" || echo.error "missing argument for '${1}'" || shift "${#}"
	done
	unset _s _p

	utils.check-errors || return "${?}"

	##########################################

	case "${loading_original_env}" in
		( false ) ;;  # only display help for originally requested environment
		( true )
			local show_help="$(normalize.boolean --variable SCWRYPTS_ENVIRONMENT__SHOW_ENV_HELP --default true --mode echo)"
			case "${show_help}" in
				( false )
					echo "---  # current scwrypts environment = ${environment_name}"
					;;

				( true )
					echo "
						#
						# current scwrypts environment = ${environment_name}
						#
						# - metadata tags are READONLY; changes to any key which starts with a
						#   '.' followed by all-caps (e.g. '.DESCRIPTION') will be ignored on
						#   save
						#
						# - value precedence is as follows (lower number is higher priority):
						#    0. runtime environment variable '__override' value
						#    1. the value from the 'value' key
						#    2. the value from the '.PARENTVALUE' (if 'value' key is null)
						#    3. a user-selected value from the 'selection' list
						#    4. a user-selected value from the '.PARENTSELECTION' list
						#
						# - values are used like environment variables, although most scalar
						#   values are permitted, they are converted to strings or string arrays
						#   before use; string 'null' is OK, but null-type means not configured
						#
						# - for 'value'     null-type / empty = not configured
						# - for 'selection' null-type / empty / empty-list = not configured
						#
						---
					"
					;;
			esac | sed 's/\(^\s\+\|\s\+$\)//g; /^$/d'
			;;
	esac

	{
		# the full template ensures all empty keys are available in the edit UI
		scwrypts.environment.get-full-template.with-value-keys

		case "${loading_original_env}" in
			( false ) ;; # don't loop through parents outside of original environment
			( true )
				local parent_environment_name
				for parent_environment_name in $(scwrypts.environment.common.get-parent-env-names "${environment_name}")
				do
					echo ---
					scwrypts.environment.get-enriched-user-yaml.zsh-cache --parent "${parent_environment_name}" \
						| sed '
							s/^\(\s\+\)\(value\|selection\):/\1.PARENT\U\2:/
							' \
						| utils.yq '.
							| del(.. | select(has(".PARENTVALUE") and .".PARENTVALUE" == null).".PARENTVALUE")
							| del(.. | select(has(".PARENTSELECTION") and (.".PARENTSELECTION" | length) == 0).".PARENTSELECTION")
							| del(.. | select(has(".PARENTSELECTION") and has(".PARENTVALUE")).".PARENTSELECTION")
							' \
						;
				done
				unset parent_environment_name
				;;
		esac

		local group group_config_file
		for group in ${SCWRYPTS_GROUPS[@]}
		do
			group_config_file="$(scwrypts.environment.common.get-env-file "${environment_name}" "${group}")"

			touch -- "${group_config_file}"

			[[ "$(head -n1 "${group_config_file}")" =~ ^---$ ]] \
				|| echo ---

			cat -- "${group_config_file}"
		done
	} \
		| scwrypts.environment.common.combine-template-files \
		| utils.yq -P \
		| sed -z 's/\n[a-z]/\n&/g' \
		| sed 's/value: null$/value:/; /\svalue:/G' \
		;
}
