#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use utils

#####################################################################

SCWRYPTS__SELECT_ENV() {
	SCWRYPTS__GET_ENV_NAMES | FZF 'select an environment'
}

SCWRYPTS__SELECT_OR_CREATE_ENV() {
	SCWRYPTS__GET_ENV_NAMES | FZF_TAIL 'select / create an environment'
}

SCWRYPTS__GET_ENV_FILE() {
	local NAME="$1"

	echo "$SCWRYPTS_ENV_PATH/$NAME"

	SCWRYPTS__GET_ENV_NAMES | grep -q $NAME \
		|| { ERROR "no environment '$NAME' exists"; return 1; }
}

SCWRYPTS__GET_ENV_TEMPLATE_FILES() {
	local GROUP
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		eval echo '$SCWRYPTS_ENV_TEMPLATE__'$GROUP
	done
}

SCWRYPTS__GET_ENV_NAMES() {
	SCWRYPTS__INIT_ENVIRONMENTS || {
		ERROR 'environment initialization error'
		return 1
	}
	ls "$SCWRYPTS_ENV_PATH" | sort -r
}

SCWRYPTS__INIT_ENVIRONMENTS() {
	[ ! -d "$SCWRYPTS_ENV_PATH" ] && mkdir -p "$SCWRYPTS_ENV_PATH"
	[[ $(ls "$SCWRYPTS_ENV_PATH" | wc -l) -gt 0 ]] && return 0

	STATUS "initializing environments for scwrypts"

	local BASIC_ENV
	for BASIC_ENV in local dev prod
	do
		GENERATE_TEMPLATE > "$SCWRYPTS_ENV_PATH/$BASIC_ENV"
	done
}

#####################################################################

_SED() { sed --follow-symlinks $@; }

GENERATE_TEMPLATE() {
	echo "#!/bin/zsh"
	echo '#####################################################################'
	echo "### scwrypts runtime configuration ##################################"
	echo '#####################################################################'
	local FILE GROUP CONTENT
	local VARIABLE DESCRIPTION
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		FILE=$(eval echo '$SCWRYPTS_ENV_TEMPLATE__'$GROUP)

		CONTENT=$(GET_VARIABLE_NAMES "$FILE" | sed 's/^/export /; s/$/=/')

		while read DESCRIPTION_LINE
		do
			VARIABLE=$(echo $DESCRIPTION_LINE | sed 's/ \+| .*$//')
			DESCRIPTION=$(echo $DESCRIPTION_LINE | sed 's/^.* | //')
			[ ! $DESCRIPTION ] && continue

			CONTENT=$(echo "$CONTENT" | sed "/^export $VARIABLE=/i #" | sed "/^export $VARIABLE=/i # $DESCRIPTION")
		done < <(_SED -n '/^[^ ]\+ \+| /p' "$FILE.descriptions")

		echo "$CONTENT" | sed 's/^#$//'
		echo '\n#####################################################################'
	done
}

GET_VARIABLE_NAMES() {
	local FILE="$1"
	grep '^export' "$FILE" \
		| sed 's/^export //; s/=.*//' \
		| grep -v '__[a-z]\+$' \
		;
}

