utils.notify-send() {
	utils.dependencies.check notify-send --optional &>/dev/null || {
		echo.warning "cannot send desktop notifications"
		utils.notify-send() { true; }
		return 0
	}

	[ "${SCWRYPT_GROUP}" ] && [ "${SCWRYPT_NAME}" ] \
		&& local title="scwrypts/${SCWRYPT_GROUP} ${SCWRYPT_NAME}" \
		|| local title="zsh"

	notify-send "${title}" "${@}"
}
