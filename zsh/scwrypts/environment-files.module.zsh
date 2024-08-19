#####################################################################

use utils

#####################################################################

SCWRYPTS__SELECT_ENV() {
	SCWRYPTS__GET_ENV_NAMES | FZF 'select an environment'
}

SCWRYPTS__SELECT_OR_CREATE_ENV() {
	SCWRYPTS__GET_ENV_NAMES | FZF_USER_INPUT 'select / create an environment'
}

SCWRYPTS__GET_ENV_FILES() {
	local NAME="$1"

	local FILENAMES=$(
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		echo "$SCWRYPTS_ENV_PATH/$GROUP/$NAME"
	done
	)

	echo $FILENAMES | grep 'environments/scwrypts/'
	echo $FILENAMES | grep -v 'environments/scwrypts/' | sort

	SCWRYPTS__GET_ENV_NAMES | grep -q $NAME \
		|| { echo.error "no environment '$NAME' exists"; return 1; }
}

SCWRYPTS__GET_ENV_FILE() {
	local NAME="$1"
	local GROUP="$2"

	[ ! $GROUP ] && { echo.error 'must provide group'; return 1; }

	echo "$SCWRYPTS_ENV_PATH/$GROUP/$NAME"

	SCWRYPTS__GET_ENV_NAMES | grep -q $NAME \
		|| { echo.error "no environment '$NAME' exists"; return 1; }

	[ -f "$SCWRYPTS_ENV_PATH/$GROUP/$NAME" ] || {
		mkdir -p "$SCWRYPTS_ENV_PATH/$GROUP"
		touch "$SCWRYPTS_ENV_PATH/$GROUP/$NAME"
	}
	[ -f "$SCWRYPTS_ENV_PATH/$GROUP/$NAME" ] \
		|| { echo.error "missing environment file for '$GROUP/$NAME'"; return 2; }
}

SCWRYPTS__GET_ENV_TEMPLATE_FILES() {
	local GROUP
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		echo "$(scwrypts.config.group "${GROUP}" root)/.config/env.template"
	done
}

SCWRYPTS__GET_ENV_NAMES() {
	SCWRYPTS__INIT_ENVIRONMENTS || {
		echo.error 'environment initialization error'
		return 1
	}
	[ $REQUIRED_ENVIRONMENT_REGEX ] && {
		ls "$SCWRYPTS_ENV_PATH/scwrypts" | grep "$REQUIRED_ENVIRONMENT_REGEX" | sort -r
	} || {
		ls "$SCWRYPTS_ENV_PATH/scwrypts" | sort -r
	}
}

SCWRYPTS__INIT_ENVIRONMENTS() {
	[ ! -d "$SCWRYPTS_ENV_PATH" ] && mkdir -p "$SCWRYPTS_ENV_PATH"
	[[ $(ls "$SCWRYPTS_ENV_PATH" | wc -l) -gt 0 ]] && return 0

	echo.status "initializing environments for scwrypts"

	local BASIC_ENV
	for BASIC_ENV in local dev prod
	do
		for GROUP in ${SCWRYPTS_GROUPS[@]}
		do
			mkdir -p "$SCWRYPTS_ENV_PATH/$GROUP"
			GENERATE_TEMPLATE > "$SCWRYPTS_ENV_PATH/$GROUP/$BASIC_ENV"
		done
	done
}

#####################################################################

_SED() { sed --follow-symlinks $@; }

GENERATE_TEMPLATE() {
    [ ! $GROUP ] && { echo.error 'must provide GROUP'; return 1; }
    DIVIDER='#####################################################################'
    HEADER='### scwrypts runtime configuration '
    [[ GROUP =~ ^scwrypts$ ]] || HEADER="${HEADER}(group '$GROUP') "
    printf "#!/bin/zsh\n$DIVIDER\n$HEADER%s\n$DIVIDER\n" "${DIVIDER:${#$(echo "$HEADER")}}"

    local FILE CONTENT
    local VARIABLE DESCRIPTION
	FILE="$(scwrypts.config.group "${GROUP}" root)/.config/env.template"

    CONTENT=$(GET_VARIABLE_NAMES "$FILE" | sed 's/^/export /; s/$/=/')

    while read DESCRIPTION_LINE
    do
        VARIABLE=$(echo $DESCRIPTION_LINE | sed 's/ \+| .*$//')
        DESCRIPTION=$(echo $DESCRIPTION_LINE | sed 's/^.* | //')
        [ ! $DESCRIPTION ] && continue

        CONTENT=$(echo "$CONTENT" | sed "/^export $VARIABLE=/i #" | sed "/^export $VARIABLE=/i # $DESCRIPTION")
    done < <(_SED -n '/^[^ ]\+ \+| /p' "$FILE.descriptions")

    echo "$CONTENT" | sed 's/^#$//'
}

GET_VARIABLE_NAMES() {
	local FILE="$1"
	grep '^export' "$FILE" \
		| sed 's/^export //; s/=.*//' \
		| grep -v '__[a-z]\+$' \
		;
}
