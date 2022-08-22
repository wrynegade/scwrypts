__CHECK_REQUIRED_ENV() {
	local VAR ERROR=0
	for VAR in $*; do __CHECK_ENV_VAR $VAR || ((ERROR+=1)); done
	return $ERROR
}

__CHECK_ENV_VAR() {
	local NAME="$1"
	[ ! $NAME ] && return 1

	local OPTIONAL="$2"
	local DEFAULT_VALUE="$3"

	local VALUE=$(eval echo '$'$NAME)
	[ $VALUE ] && return 0

	local SELECTION_VALUES=$(eval echo '$'$NAME'__select' | sed 's/,/\n/g')
	[ $SELECTION_VALUES ] && {
		local SELECTION=$(echo $SELECTION_VALUES | __FZF "select a value for '$NAME'")
		[ $SELECTION ] && export VALUE=$SELECTION
	}
	[ $VALUE ] && return 0

	[ $__SCWRYPT ] && {
		# scwrypts exclusive (missing vars staged in env.template)
		local LINE="export $NAME="

		grep -q -- "^$LINE" "$__ENV_TEMPLATE" || {
			__STATUS 'staging new variable in template'

			echo "$LINE" >> "$__ENV_TEMPLATE" \
				&& __RUN_SCWRYPT zsh/scwrypts/environment/synchronize -- --no-prompt
		}
	}

	[ $OPTIONAL ] && {
		[ $DEFAULT_VALUE ] && $NAME="$DEFAULT_VALUE"
		return 0
	} || {
		 __ERROR "'$NAME' required"
		return 1
	}
}
