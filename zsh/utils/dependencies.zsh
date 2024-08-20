utils.dependencies.check-all() {
	local DEP ERRORS=0
	local SCWRYPTS_LOG_LEVEL=1
	[ ! ${E} ] && E=echo.error

	DEPENDENCIES=($(echo ${DEPENDENCIES} | sed 's/ \+/\n/g' | sort -u))

	for DEP in ${DEPENDENCIES[@]}; do utils.dependencies.check ${DEP} || ((ERRORS+=1)); done
	utils.dependencies.check-coreutils || ((ERRORS+=$?))

	return ${ERRORS}
}

utils.dependencies.check() {
	local DEPENDENCY="$1"
	[ ! ${DEPENDENCY} ] && return 1
	command -v ${DEPENDENCY} >/dev/null 2>&1 || {
		[[ ${OPTIONAL} -eq 1 ]] \
			&& echo.warning "application '$1' preferred but not available on PATH $(utils.dependencies.credits $1)" \
			|| echo.error   "application '$1' required but not available on PATH $(utils.dependencies.credits $1)" \
			;
		return 1
	}

	[[ ${DEPENDENCY} =~ ^yq$ ]] && {
		yq --version | grep -q mikefarah \
			|| echo.warning 'detected kislyuk/yq but mikefarah/yq is preferred (compatibility may vary)'
	}

	return 0
}

utils.dependencies.check-coreutils() {
	local COREUTILS=(awk find grep sed readlink)
	local MISSING_DEPENDENCY_COUNT=0
	local NON_GNU_DEPENDENCY_COUNT=0

	local UTIL
	for UTIL in $(echo ${COREUTILS})
	do
		utils.dependencies.check ${UTIL} || { ((MISSING_DEPENDENCY_COUNT+=1)); continue; }

		${UTIL} --version 2>&1 | grep 'GNU' | grep -qv 'BSD' || {
			echo.warning "non-GNU version of ${UTIL} detected"
			((NON_GNU_DEPENDENCY_COUNT+=1))
		}
	done

	[[ ${NON_GNU_DEPENDENCY_COUNT} -gt 0 ]] && {
		echo.warning 'scripts rely on GNU coreutils; compatibility may vary'
		utils.os.is-macos && echo.reminder 'GNU coreutils can be installed and linked through Homebrew'
	}

	return ${MISSING_DEPENDENCY_COUNT}
}

utils.dependencies.credits() {
	return 0
	# scwrypts exclusive ("credits" pulled from README files)
	[ ! ${__SCWRYPT} ] && return 0

	local COMMAND="$1"
	[[ $COMMAND =~ - ]] && COMMAND=$(echo $COMMAND | sed 's/-/--/g')
	(
	cd "$(scwrypts.config.group scwrypts root)"
	cat ./**/README.md \
		| grep 'Generic Badge' \
		| sed -n "s/.*Generic Badge.*-$COMMAND-.*(/(/p" \
		;
	)
}
