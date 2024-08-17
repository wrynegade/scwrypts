__CHECK_DEPENDENCIES() {
	local DEP ERRORS=0
	local SCWRYPTS_LOG_LEVEL=1
	[ ! $E ] && E=ERROR

	DEPENDENCIES=($(echo $DEPENDENCIES | sed 's/ \+/\n/g' | sort -u))

	for DEP in ${DEPENDENCIES[@]}; do __CHECK_DEPENDENCY $DEP || ((ERRORS+=1)); done
	__CHECK_COREUTILS || ((ERRORS+=$?))

	return $ERRORS
}

__CHECK_DEPENDENCY() {
	local DEPENDENCY="$1"
	[ ! $DEPENDENCY ] && return 1
	command -v $DEPENDENCY >/dev/null 2>&1 || {
		$E "application '$1' "$([[ $OPTIONAL -eq 1 ]] && echo preferred || echo required)" but not available on PATH $(__CREDITS $1)"
		return 1
	}

	[[ $DEPENDENCY =~ ^yq$ ]] && {
		yq --version | grep -q mikefarah \
			|| WARNING 'detected kislyuk/yq but mikefarah/yq is preferred (compatibility may vary)'
	}

	return 0
}

__CHECK_COREUTILS() {
	local COREUTILS=(awk find grep sed readlink)
	local MISSING_DEPENDENCY_COUNT=0
	local NON_GNU_DEPENDENCY_COUNT=0

	local UTIL
	for UTIL in $(echo $COREUTILS)
	do
		__CHECK_DEPENDENCY $UTIL || { ((MISSING_DEPENDENCY_COUNT+=1)); continue; }

		$UTIL --version 2>&1 | grep 'GNU' | grep -qv 'BSD' || {
			WARNING "non-GNU version of $UTIL detected"
			((NON_GNU_DEPENDENCY_COUNT+=1))
		}
	done

	[[ $NON_GNU_DEPENDENCY_COUNT -gt 0 ]] && {
		WARNING 'scripts rely on GNU coreutils; compatibility may vary'
		IS_MACOS && REMINDER 'GNU coreutils can be installed and linked through Homebrew'
	}

	return $MISSING_DEPENDENCY_COUNT
}
