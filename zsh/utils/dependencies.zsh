__CHECK_DEPENDENCIES() {
	local DEPENDENCY
	for DEPENDENCY in $*
	do
		__CHECK_DEPENDENCY $DEPENDENCY || ((__DEPENDENCY_ERROR+=1))
	done

	__CHECK_COREUTILS || ((__DEPENDENCY_ERROR+=$?))

	return $__DEPENDENCY_ERROR
}

__CHECK_DEPENDENCY() {
	local DEPENDENCY="$1"
	[ ! $DEPENDENCY ] && return 1

	command -v $DEPENDENCY >/dev/null 2>&1 || {
		__ERROR "'$1' required but not installed. $(__CREDITS $1)"
		return 1
	}
}

__CHECK_COREUTILS() {
	local COREUTILS=(awk find grep sed)
	local MISSING_DEPENDENCY_COUNT=0
	local NON_GNU_DEPENDENCY_COUNT=0

	local UTIL
	for UTIL in $(echo $COREUTILS)
	do
		__CHECK_DEPENDENCY $UTIL || { ((MISSING_DEPENDENCY_COUNT+=1)); continue; }

		$UTIL --version 2>&1 | grep -q 'GNU' || {
			__WARNING "non-GNU version of $UTIL detected"
			((NON_GNU_DEPENDENCY_COUNT+=1))
		}
	done

	[[ $NON_GNU_DEPENDENCY_COUNT -gt 0 ]] && {
		__WARNING 'scripts rely on GNU coreutils; functionality may be limited'
		__IS_MACOS && __REMINDER 'GNU coreutils can be installed and linked through Homebrew'
	}

	return $MISSING_DEPENDENCY_COUNT
}
