#####################################################################

use scwrypts/environment/common
use scwrypts/environment/get-full-template
use scwrypts/environment/select-env

use zsh-cache/reset

#####################################################################

[ "${SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE}" ] \
	|| export SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE=basic

${scwryptsmodule}() {
	local DESCRIPTION='Update a scwrypts environment configuration'
	local PARSERS=(scwrypts.zshparse.environment-name)
	eval "$(utils.parse.autosetup)"
	##########################################

	local TEMP_CONFIG_FILE="${SCWRYPTS_TEMP_PATH_SOCKET}/environment.temp.yaml"

	[[ -f "${TEMP_CONFIG_FILE}" ]] && {
		echo.error "temp config file already exists at '$TEMP_CONFIG_FILE'\nis another environment update in-progress?"
		echo.reminder "
			if you are certain no other environment update is in progress, you can resolve with
			rm -- ${(q)TEMP_CONFIG_FILE}
		"
		return 1
	}

	"${edit_mode_helper}"
	local exit_code="${?}"

	rm "${TEMP_CONFIG_FILE}" 2>/dev/null

	return ${exit_code}
}

#####################################################################

${scwryptsmodule}.parse.locals() {
	local edit_mode="${SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE}"
	local edit_mode_helper
	local edit_mode_args=()
	local from_existing
}

${scwryptsmodule}.parse() {
	local parsed=0

	case "${1}" in
		( --mode )
			parsed=2
			edit_mode_args+=("${1} ${2}")
			edit_mode="${2}"
			;;

		( --create-from-existing )
			parsed=2
			edit_mode_args+=("${1}")
			edit_mode=copy
			from_existing="${2}"
			;;
	esac

	return "${parsed}"
}

${scwryptsmodule}.parse.usage() {
	USAGE__options+="
		--mode <string>   update execution mode (default: ${SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE})
		   modes:
		      basic     : create or edit environment with all tooltips and metadata
		      quiet     : create or edit a compact environment with minimal metadata
		      init      : create a new environment with no edit prompt
		      delete    : delete target environment
		      recursive : (advanced) edit all inherited environments, starting from deepest parent
		      copy      : (see --create-from-existing; most likely you don't need to set this flag)

		--create-from-existing <string>   name of the environment to copy
	"
}

${scwryptsmodule}.parse.validate() {
	[[ "${#edit_mode_args[@]}" -le 1 ]] \
		|| echo.error "incompatible arguments ${(q)edit_mode_args[@]}" \
		|| return


	[[ "${edit_mode}" ]] \
		&& edit_mode_helper="scwrypts.environment.update.edit.${edit_mode}" \
		&& command -v "${edit_mode_helper}" &>/dev/null \
		|| echo.error "invalid edit mode '${edit_mode}'" \
		;

	case "${edit_mode}" in
		( copy )
			[[ "${from_existing}" ]] || from_existing="$(scwrypts.environment.select-env)"
			[[ "${from_existing}" ]] || echo.error "cannot work in '${edit_mode}' without existing target"
			;
	esac

	if [[ "${from_existing}" ]]
	then
		[[ "$(scwrypts.environment.common.find-env-files-by-name "${from_existing}" | wc -l)" -gt 0 ]] \
			|| echo.error "no such environment '${from_existing}' exists"
	fi
}

#####################################################################

${scwryptsmodule}.edit.basic() {
	scwrypts.environment.get-enriched-user-yaml \
		--environment-name $environment_name \
		> "$TEMP_CONFIG_FILE"

	utils.io.edit "$TEMP_CONFIG_FILE"

	scwrypts.environment.update.update-user-configs "${environment_name}"
}

${scwryptsmodule}.edit.quiet() {
	echo "---  # $environment_name" > "$TEMP_CONFIG_FILE"
	scwrypts.environment.get-enriched-user-yaml \
			--environment-name $environment_name \
		| utils.yq '.
			| del(.. | select(has(".ENVIRONMENT")).".ENVIRONMENT")
			| del(.. | select(has(".GROUP")).".GROUP")
			| del(.. | select(has(".DESCRIPTION")).".DESCRIPTION")
			| del(.. | select(has("selection") and (.selection == null or (.selection | length) == 0)).selection)
			| del(.. | select(has("selection") and has("value") and .value == null).value)
			| del(.. | select(has(".PARENTVALUE") and has("value") and .value == null).value)
			' \
		>> "$TEMP_CONFIG_FILE"

	utils.io.edit "$TEMP_CONFIG_FILE"

	scwrypts.environment.update.update-user-configs "${environment_name}"
}

${scwryptsmodule}.edit.recursive() {
	local recursive_edit_mode="${SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE}"
	[[ "${recursive_edit_mode}" =~ ^recursive$ ]] \
		&& recursive_edit_mode=quiet

	local parent_environment_name
	for parent_environment_name in \
		$(scwrypts.environment.common.get-parent-env-names "$environment_name") \
		$environment_name
		;
	do
		echo.status "editing environment '${parent_environment_name}'"
		scwrypts.environment.update \
			--environment-name "${parent_environment_name}" \
			--mode "${recursive_edit_mode}" \
			;
	done
}

${scwryptsmodule}.edit.init() {
	[ -f "$(scwrypts.environment.common.get-env-file)" ]

	scwrypts.environment.get-enriched-user-yaml \
		--environment-name "${environment_name}" \
		> "${TEMP_CONFIG_FILE}"

	scwrypts.environment.update.update-user-configs "${environment_name}"
}

${scwryptsmodule}.edit.copy() {
	local group_config_filename SOURCE_CONFIG_FILENAME
	for group in ${SCWRYPTS_GROUPS[@]}
	do
		cp \
			"$(scwrypts.environment.common.get-env-file "${FROM_EXISTING}" "${group}")" \
			"$(scwrypts.environment.common.get-env-file "${environment_name}" "${group}")" \
			2>/dev/null \
			;
	done

	scwrypts.environment.get-enriched-user-yaml \
		--environment-name "${environment_name}" \
		> "${TEMP_CONFIG_FILE}"

	scwrypts.environment.update.update-user-configs "${environment_name}"
}

${scwryptsmodule}.edit.delete() {
	touch "$TEMP_CONFIG_FILE"

	local ERRORS=0 group group_config_filename
	for group in ${SCWRYPTS_GROUPS[@]}
	do
		local group_config_filename="$(scwrypts.environment.common.get-env-file "${environment_name}" "${group}")"
		[ -f "${group_config_filename}" ] || {
			echo.status "nothing to cleanup for ${environment_name}/${group}"
			continue
		}

		rm -- "${group_config_filename}" \
			&& echo.success "deleted '${group_config_filename}'" \
			|| echo.error "unable to delete '${group_config_filename}'" \
			;
	done

	return "${ERRORS}"
}

#####################################################################
#####################################################################
#####################################################################

export __SCWRYPTS_ENVIRONMENT__WORKFLOW_IS_CHANGE_SAFE=false
${scwryptsmodule}.update-user-configs() {
	local environment_name="${1}"
	[[ "${environment_name}" ]] || return 2

	# reinject all metadata, since the update function is allowed to strip it
	local new_configuration="$({
		scwrypts.environment.get-full-template.with-value-keys --environment "${environment_name}"
		echo ---
		cat -- "${TEMP_CONFIG_FILE}"
	} | scwrypts.environment.common.combine-template-files)"
	[[ "${new_configuration}" ]] || return 1


	local metadata_delete_query="$(
		echo "${new_configuration}" \
			| sed -n 's/^\s\+\(\.[-A-Za-z_:]\+\):.*$/ | del(.. | select(has("\1"))."\1")/p' \
			| sort --unique \
			)"

	local group group_config_filename group_config
	for group in ${SCWRYPTS_GROUPS[@]}
	do
		local group_config="$(echo "${new_configuration}" \
			| utils.yq ".
					| del(.. | select(has(\".PARENTVALUE\") and has(\"value\") and .\".PARENTVALUE\" == .value))
					| del(.. | select(has(\".PARENTSELECTION\") and has(\"selection\") and .\".PARENTSELECTION\" == .selection))
					| del(.. | select(has(\".GROUP\") and .\".GROUP\" != \"${group}\"))
					| del(.. | select(has(\"selection\") and (.selection == null or (.selection | length) == 0)).selection)
					| del(.. | select(has(\"value\") and .value == null).value)
					${metadata_delete_query}
				" \
		)"

		while echo "$group_config" | grep -q '{}'
		do
			group_config="$(echo "${group_config}" | utils.yq 'del(.. | select(tag == "!!map" and length == 0))')"
		done

		[ "${group_config}" ] || group_config='# no configuration set'

		echo "---  # ${environment_name} > ${group}\n${group_config}" > "$(scwrypts.environment.common.get-env-file "${environment_name}" "${group}")"
	done

	[[ "${environment_name}" == "${SCWRYPTS_ENV}" ]] && [[ "${__SCWRYPTS_ENVIRONMENT__WORKFLOW_IS_CHANGE_SAFE}" =~ false ]] && {
		echo.warning "current scwrypts environment has changed"
		export __SCWRYPTS_ENVIRONMENT__USER_ENVIRONMENT=
	}

	zsh-cache.reset.all

	return 0
}
