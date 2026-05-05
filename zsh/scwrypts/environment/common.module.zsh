#####################################################################

DEPENDENCIES+=(grep jq sed sort yq)

#####################################################################

${scwryptsmodule}.get-env-names() {
	scwrypts.environment.common.find-env-names \
		| grep "${REQUIRED_ENVIRONMENT_REGEX:-.}"
}

${scwryptsmodule}.get-env-file() {  # provides the fully qualified path to the group config file
	local environment_name="${1}" group="${2}"
	[[ "${environment_name}" ]] && [[ "${group}" ]] \
		|| echo.error 'cannot determine environment file without name ($1) and group ($2)' \
		|| return 1

	echo "${SCWRYPTS_ENV_PATH}/${environment_name}.${group}.env.yaml"
}

#####################################################################

${scwryptsmodule}.get-parent-env-names() {  # highest-level parent first; e.g. for 'a.b.c.d', returns (a a.b a.b.c)
	local environment_name="${1}"
	[[ "${environment_name}" ]] || return 0

	local parent_environment_names=()
	while [[ "${environment_name}" ]]
	do
		environment_name="$(echo "${environment_name}" | sed -n 's/\.[^.]\+$//p')"
		[[ "${environment_name}" ]] && parent_environment_names+=("${environment_name}")
	done

	printf '%s\n' "${parent_environment_names[@]}" | sort
}

#####################################################################

${scwryptsmodule}.find-env-files() {
	find "${SCWRYPTS_ENV_PATH}/" -mindepth 1 -maxdepth 1 -type f -name \*.env.yaml 2>/dev/null
}

${scwryptsmodule}.find-env-names() {
	scwrypts.environment.common.find-env-files \
		| sed "s|^${SCWRYPTS_ENV_PATH}/||; s|\\.[^.]\\+\\.env\\.yaml$||" \
		| sort --reverse --unique \
		;
}

${scwryptsmodule}.find-env-files-by-name() {
	local environment_name="${1}"
	[[ "${environment_name}" ]] || return 1

	find "${SCWRYPTS_ENV_PATH}/" -mindepth 1 -maxdepth 1 -type f -name ${environment_name}.\*.env.yaml 2>/dev/null
}

#####################################################################

${scwryptsmodule}.combine-template-files() {
	# combine files & set 'somethingEmpty: {}' to 'somethingEmpty:'
	utils.yq.combine-files | sed 's/: {}$/:/'
}

#####################################################################

${scwryptsmodule}.get-all-template-files() {
	# produces a complete list of template env.yaml across all known scwrypts groups
	local files=()

	local group file
	for group in "${SCWRYPTS_GROUPS[@]}"
	do
		file="$(scwrypts.config.group "${group}" root)/.config/env.yaml"
		[[ -f "${file}" ]] && files+=("${group}:${file}")
	done

	printf '%s\n' "${files[@]}"
}

${scwryptsmodule}.get-all-template-files.only-filenames() {
	scwrypts.environment.common.get-all-template-files | sed 's/^[^:]\+://'
}

${scwryptsmodule}.get-all-configuration-files() {
	# produces a complete list of user environment configurations for the target environment
	local PARSERS=(scwrypts.zshparse.environment-name)
	eval "$(utils.parse.autosetup)"
	##########################################

	local files=()

	local _environment_name file group group_config_file
	for _environment_name in \
		$(scwrypts.environment.common.get-parent-env-names "${environment_name}") \
		${environment_name} \
		;
	do
		for group in "${SCWRYPTS_GROUPS[@]}"
		do
			group_config_file="$(scwrypts.environment.common.get-env-file "${_environment_name}" "${group}")"
			[[ -f "${group_config_file}" ]] && files+=("${group_config_file}")
		done
	done

	printf '%s\n' "${files[@]}"
}

${scwryptsmodule}.get-environment-module-files() {
	find "$(scwrypts.config.group scwrypts zshlibrary)/scwrypts/environment" -type f
}
