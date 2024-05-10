#####################################################################

use scwrypts/environment/common

#####################################################################

${scwryptsmodule}() {
	[ ${CI} ] && return 0

	mkdir -p "${SCWRYPTS_ENV_PATH}"
	[[ $(scwrypts.environment.common.find-env-files | wc -l) -gt 0 ]] && return 0

	[[ $(scwrypts.environment.common.find-legacy-env-files | wc -l) -gt 0 ]] && {
		scwrypts.environment.legacy.convert
		return $?
	}

	#
	# usually we don't want to do this, but waiting to load these is critical
	# to scwrypts runtime performance!
	#
	use scwrypts/environment/update

	echo.status "initializing environments for scwrypts"

	local BASIC_ENV
	for BASIC_ENV in local dev prod
	do
		scwrypts.environment.update --environment-name "${BASIC_ENV}"
	done
}

#####################################################################

scwrypts.environment.legacy.find-env-files() {
	find "${SCWRYPTS_ENV_PATH}/" -mindepth 2 -maxdepth 2 -type f 2>/dev/null
}

scwrypts.environment.legacy.find-env-names() {
	scwrypts.environment.legacy.find-env-files \
		| sed 's|.*/||' \
		| sort --unique \
		;
}

#####################################################################

scwrypts.environment.legacy.convert() {
	local GROUP GROUP_ROOT
	local GROUP_TEMPLATE_FILENAME LEGACY_TEMPLATE_FILENAME

	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		GROUP_ROOT="$(scwrypts.config.group ${GROUP} root)"
		GROUP_TEMPLATE_FILENAME="${GROUP_ROOT}/.config/env.yaml"
		LEGACY_TEMPLATE_FILENAME="${GROUP_ROOT}/.config/env.template"

		[ ! -f "${GROUP_TEMPLATE_FILENAME}" ] && [ -f "${LEGACY_TEMPLATE_FILENAME}" ] && {
			scwrypts.environment.legacy.convert.v4-to-v5.template-file
		}

		[ -f "$GROUP_TEMPLATE_FILENAME" ] && echo.success "environment template '$GROUP' OK"
	done

	local ENVIRONMENT_NAME
	local GROUP_CONFIG_FILENAME LEGACY_CONFIG_FILENAME
	for ENVIRONMENT_NAME in $(scwrypts.environment.legacy.find-env-names)
	do
		local MIGRATE_GROUP=false
		echo.status "checking '${ENVIRONMENT_NAME}' configuration files"
		for GROUP in ${SCWRYPTS_GROUPS[@]}
		do
			GROUP_CONFIG_FILENAME="$(scwrypts.environment.common.get-env-filename "${ENVIRONMENT_NAME}" "${GROUP}")"
			LEGACY_CONFIG_FILENAME="${SCWRYPTS_ENV_PATH}/${GROUP}/${ENVIRONMENT_NAME}"

			[ ! -f "${GROUP_CONFIG_FILENAME}" ] && [ -f "${LEGACY_CONFIG_FILENAME}" ] && {
				MIGRATE_GROUP=true
			}
		done

		[[ ${MIGRATE_GROUP} =~ true ]] && {
			scwrypts.environment.legacy.convert.v4-to-v5.config-file \
				&& echo.success "successfully migrated '${ENVIRONMENT_NAME}'"
		}
	done
}

scwrypts.environment.legacy.convert.v4-to-v5.template-file() {
	scwrypts.environment.legacy.convert.v4-to-v5.deprecation-warning

	echo.status "detected legacy template for '${GROUP}'; attempting v5 conversion"

	"$(scwrypts.config.group scwrypts root)/.config/create-new-env" "${GROUP_ROOT}/.config" "${GROUP}" &>/dev/null

	utils.io.edit "${GROUP_TEMPLATE_FILENAME}"

	echo.reminder "the file '${GROUP_TEMPLATE_FILENAME}' should be committed to the appropriate repository"
}

scwrypts.environment.legacy.convert.v4-to-v5.config-file() {
	scwrypts.environment.legacy.convert.v4-to-v5.deprecation-warning

	SCWRYPTS_LOG_LEVEL=4 echo.status "detected legacy environment configuration file for '${ENVIRONMENT_NAME}'; attempting v5 conversion"

	local LEGACY_CONFIG_FILE
	local LEGACY_CONFIG_VALUES="$(
	cat "${SCWRYPTS_ENV_PATH}/"*"/${ENVIRONMENT_NAME}" \
		| sed '/^#/d; /^$/d; /=$/d; /# from/d' \
		| sed -z 's/\n\s\+/ /g' \
		| sed -z 's/\n)/)/g' \
		| sed 's/( /\n(/' \
		| sed '/^(/{s/ /,/g}; s/^(\(.*\))$/[\1]/' \
		| sed '/^\[/{s|\([^][,]\+\)|"\1"|g}' \
		| sed "s/^\\[.*\\]$/'&'/" \
		| sed -z "s/\\n'\[/'[/g" \
		| sed 's/^export \([^=]\+\)=/\1: /' \
		| utils.yq --unwrapScalar=false '..style="double"' \
	)"

	local ENV_VAR NEW_TEMPLATE_KEY NEW_TEMPLATE="$(scwrypts.environment.get-full-template --reset-cache)"
	for ENV_VAR in $(echo "${LEGACY_CONFIG_VALUES}" | utils.yq -r 'keys | .[]')
	do
		NEW_TEMPLATE_KEY=$(scwrypts.environment.template.get-envvar-lookup-map | utils.yq -r ".${ENV_VAR}")
		NEW_TEMPLATE_VALUE="$(echo "${LEGACY_CONFIG_VALUES}" | utils.yq -r ".${ENV_VAR}")"
		echo "${NEW_TEMPLATE_VALUE}" | grep -q '^[[].*[]]$' \
			|| NEW_TEMPLATE_VALUE="\"${NEW_TEMPLATE_VALUE}\""

		NEW_TEMPLATE="$(
			echo "${NEW_TEMPLATE}" | utils.yq "${NEW_TEMPLATE_KEY} = ${NEW_TEMPLATE_VALUE}"
		)"
	done

	scwrypts.environment.update.update-user-configs "${NEW_TEMPLATE}" "${ENVIRONMENT_NAME}"
}

export __SCWRYPTS_ENVIRONMENT__DEPRECATION_WARNING=false
scwrypts.environment.legacy.convert.v4-to-v5.deprecation-warning() {
	[[ ${__SCWRYPTS_ENVIRONMENT__DEPRECATION_echo}.warning =~ true ]] && return 0

	echo.warning "DEPRECATED : the v4 to v5 environment migration is temporary and will be removed in 5.2"
	export __SCWRYPTS_ENVIRONMENT__DEPRECATION_WARNING=true
}
