utils.notify-send() {
	utils.dependencies.check notify-send &>/dev/null || {
		echo.warning "missing 'notify-send'; cannot send desktop notifications"
		utils.notify-send() { true; }
		return 0
	}

	[ "${SCWRYPT_GROUP}" ] && [ "${SCWRYPT_NAME}" ] \
		&& local TITLE="scwrypts/${SCWRYPT_GROUP} ${SCWRYPT_NAME}" \
		|| local TITLE="zsh"

	notify-send "${TITLE}" $@
}
