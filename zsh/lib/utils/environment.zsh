__CHECK_REQUIRED_ENV() {
	local SCWRYPTS_LOG_LEVEL=1
	local VAR ERROR=0
	REQUIRED_ENV=($(echo $REQUIRED_ENV | sed 's/\s\+/\n/g' | sort -u))
	for VAR in ${REQUIRED_ENV[@]}; do __CHECK_ENV_VAR $VAR || ((ERROR+=1)); done
	return $ERROR
}

__CHECK_ENV_VAR() {
	local NAME="$1"
	[ ! $NAME ] && return 1

	local OVERRIDE_VALUE=$(eval echo '$'$NAME'__override')
	[ $OVERRIDE_VALUE ] && export $NAME=$OVERRIDE_VALUE && return 0

	local OPTIONAL="$2"
	local DEFAULT_VALUE="$3"

	local VALUE=$(eval echo '$'$NAME)
	[ $VALUE ] && return 0

	local SELECTION_VALUES=$(eval echo '$'$NAME'__select' | sed 's/,/\n/g; s/ /\n/g')
	[[ $ERROR -eq 0 ]] && [[ ${#SELECTION_VALUES[@]} -gt 0 ]] && {
		local SELECTION=$(echo $SELECTION_VALUES | FZF "select a value for '$NAME'")
		[ $SELECTION ] && {
			export $NAME=$SELECTION
			return 0
		}
	}
	[ $VALUE ] && return 0

	[ $OPTIONAL ] && {
		[ $DEFAULT_VALUE ] && $NAME="$DEFAULT_VALUE"
		return 0
	} || {
		ERROR "variable '$NAME' required"
		return 1
	}
}
