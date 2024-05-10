#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use utils

#####################################################################

SCWRYPTS__SELECT_ENV() {
	SCWRYPTS__GET_ENV_NAMES | FZF 'select an environment'
}

SCWRYPTS__SELECT_OR_CREATE_ENV() {
	SCWRYPTS__GET_ENV_NAMES | FZF_USER_INPUT 'select / create an environment'
}

SCWRYPTS__FIND_ENV_FILES() {
	find "$SCWRYPTS_ENV_PATH/" -mindepth 1 -maxdepth 1 -type f -name \*.env.yaml 2>/dev/null
}

SCWRYPTS__FIND_ENV_NAMES() {
	SCWRYPTS__FIND_ENV_FILES \
		| sed "s|^$SCWRYPTS_ENV_PATH/||; s|\\.env\\.yaml$||"  \
		| sort -r \
		;
}

SCWRYPTS__GET_ENV_NAME() {
	local FILENAME="$1"
	basename -- "$FILENAME" \
			| sed -n 's/\.env\.yaml//p' \
			| grep . \
		|| ERROR "invalid scwrypts env filename '$FILENAME'"
}

SCWRYPTS__GET_ENV_FILE() {
	local NAME="$1"
	echo "$SCWRYPTS_ENV_PATH/$NAME.env.yaml"
}

SCWRYPTS__GET_ENV_TEMPLATE_FILES() {
	local GROUP
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		eval echo '$SCWRYPTS_ROOT__'$GROUP/.config/env.yaml
	done
}

SCWRYPTS__GET_ENV_NAMES() {
	SCWRYPTS__INIT_ENVIRONMENTS \
		|| ERROR 'environment initialization error' \
		|| return 1

	[ $REQUIRED_ENVIRONMENT_REGEX ] && {
		SCWRYPTS__FIND_ENV_NAMES | grep "$REQUIRED_ENVIRONMENT_REGEX"
		return $?
	}

	SCWRYPTS__FIND_ENV_NAMES
}

SCWRYPTS__INIT_ENVIRONMENTS() {
	mkdir -p "$SCWRYPTS_ENV_PATH"
	[[ $(__SCWRYPTS_ENV_FIND | wc -l) -gt 0 ]] && return 0

	STATUS "initializing environments for scwrypts"

	local BASIC_ENV TEMPLATE="$(GENERATE_TEMPLATE)"
	for BASIC_ENV in local dev prod
	do
		echo "$TEMPLATE" > "$SCWRYPTS_ENV_PATH/$BASIC_ENV.env.yaml"
	done
}

#####################################################################

GENERATE_FULL_TEMPLATE() {
	GENERATE_FULL_TEMPLATE_REFERENCE \
		| yq 'del(.. | select(has(".ENVIRONMENT")).[".ENVIRONMENT"])' \
		;
}

export __FULL_TEMPLATE_REFERENCE=
GET_COMPLETE_TEMPLATE_REFERENCE() {
	[ $__FULL_TEMPLATE_REFERENCE ] || {
		export __FULL_TEMPLATE_REFERENCE="$(__GENERATE_FULL_TEMPLATE_REFERENCE)"
	}

	echo "$__FULL_TEMPLATE_REFERENCE"
}

__GENERATE_FULL_TEMPLATE_REFERENCE() {
	local GROUP GROUP_ROOT GROUP_TEMPLATE_FILENAME LEGACY_TEMPLATE_FILENAME
	{
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		GROUP_ROOT="$(eval echo '$SCWRYPTS_ROOT__'$GROUP)"

		GROUP_TEMPLATE_FILENAME="$GROUP_ROOT/.config/env.yaml"
		LEGACY_TEMPLATE_FILENAME="$GROUP_ROOT/.config/env.template"

		[ ! -f "$GROUP_TEMPLATE_FILENAME" ] && [ -f "$LEGACY_TEMPLATE_FILENAME" ] && {
			STATUS "detected legacy template for '$GROUP'; attempting v5 conversion"
			"$SCWRYPTS_ROOT__scwrypts/.config/create-new-env" "$GROUP_ROOT/.config" "$GROUP" &>/dev/null
			EDIT "$GROUP_TEMPLATE_FILENAME"
			REMINDER "the file '$GROUP_TEMPLATE_FILENAME' should be committed to the appropriate repository"
		}

		[ -f "$GROUP_TEMPLATE_FILENAME" ] && {
			[[ $(head -n1 "$GROUP_TEMPLATE_FILENAME") =~ ^---$ ]] || echo ---
			cat "$GROUP_TEMPLATE_FILENAME"
		}
	done
	} \
		| yq eval-all '. as $item ireduce ({}; . *+ $item)' \
		| yq 'sort_keys(...)' \
		| sed 's/: {}$/:/' \
		| yq \
		;
}

__MIGRATE_ENV_FROM_V4_TO_V5() {
	# TODO
}
