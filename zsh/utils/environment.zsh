__CHECK_ENV_VARS() {
	local OPTIONAL=0
	[[ $1 =~ ^--optional$ ]] && { shift 1; OPTIONAL=1; }

	local VAR_NAME
	for VAR_NAME in $*
	do
		__CHECK_ENV_VAR $VAR_NAME $OPTIONAL || ((__ENVIRONMENT_ERROR+=1))
	done

	return $__ENVIRONMENT_ERROR
}

__CHECK_ENV_VAR() {
	local NAME="$1"
	local OPTIONAL="$2"
	local DEFAULT_VALUE="$3"

	local VALUE=$(eval echo '$'$NAME)
	[ $VALUE ] && return 0

	local LINE="export $NAME="
	local TEMPLATE="$SCWRYPTS_ROOT/.template.env"

	grep -q -- "^$LINE" "$TEMPLATE" || {
		__STATUS 'staging new variable in template'

		echo "$LINE" >> "$TEMPLATE" \
			&& NOPROMPT=1 $SCWRYPTS_ROOT/zsh/scwrypts/environment/synchronize \
			&& git add $TEMPLATE >/dev/null 2>&1 \
			&& __SUCCESS "staged '$NAME'" \
			|| {
				__WARNING  "failed to stage '$NAME'"
				__REMINDER "add/commit '$NAME' to template manually"
			}
	}

	[ $OPTIONAL ] && {
		 __ERROR "'$NAME' required"
		return 1
	} || {
		[ $DEFAULT_VALUE ] && $NAME="$DEFAULT_VALUE"
		return 0
	}
}
