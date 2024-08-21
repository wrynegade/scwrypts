#####################################################################
SCWRYPTS_VIRTUALENV__AVAILABLE_VIRTUALENVS+=(zx)
#####################################################################


virtualenv.zx.create() {
	utils.dependencies.check npm || return 1
}

virtualenv.zx.activate() {
	return 0  # npm setup is managed by package.json
}

virtualenv.zx.deactivate() {
	return 0  # npm setup is managed by package.json
}

virtualenv.zx.update() {
	local ERRORS=0
	local GROUP NPM_ROOT

	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		case "$(eval echo "\$SCWRYPTS_GROUP_CONFIGURATION__${GROUP}__type")" in
			( '' )
				NPM_ROOT="$(scwrypts.config.group ${GROUP} root)/zx"
				;;
			( zx )
				NPM_ROOT="$(scwrypts.config.group ${GROUP} root)"
				;;
			( * )
				continue
				;;
		esac

		[ "${NPM_ROOT}" ] && [ -d "${NPM_ROOT}" ] \
			|| echo.error "group ${GROUP} appears to be misconfigured" \
			|| continue

		( cd "${NPM_ROOT}" && npm install; ) \
			|| echo.error "something went wrong during npm install for ${GROUP}" \
			|| continue
	done

	return ${ERRORS}
}
