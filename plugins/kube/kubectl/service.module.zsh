#####################################################################

use --group kube kubectl/cli
use --group kube kubectl/context
use --group kube kubectl/namespace

#####################################################################

${scwryptsmodule}.serve() {
	[ "${CONTEXT}" ] || local CONTEXT="$(kube.kubectl.context.get)"
	[ "${CONTEXT}" ] || echo.error 'must configure a context in which to serve'

	[ "${NAMESPACE}" ] || local NAMESPACE="$(kube.kubectl.namespace.get)"
	[ "${NAMESPACE}" ] || echo.error 'must configure a namespace in which to serve'

	utils.check-errors --no-usage || return 1

	[ "${SERVICE}" ] && SERVICE="$(kube.kubectl.service.list | jq -c "select (.service == \"${SERVICE}\")" || echo ${SERVICE})"
	[ "${SERVICE}" ] || local SERVICE="$(kube.kubectl.service.select)"
	[ "${SERVICE}" ] || echo.error 'must provide or select a service'

	kube.kubectl.service.list | grep -q "^${SERVICE}$"\
		|| echo.error "no service '${SERVICE}' in '${CONFIG}/${NAMESPACE}'"

	utils.check-errors --no-usage || return 1

	##########################################

	SERVICE_PASSWORD="$(kube.kubectl.service.get-password)"
	kube.kubectl.service.parse

	echo.reminder "attempting to serve ${NAMESPACE}/${SERVICE_NAME}:${SERVICE_PORT}"
	[ "${SERVICE_PASSWORD}" ] && echo.reminder "password : ${SERVICE_PASSWORD}"

	kube.cli port-forward "service/${SERVICE_NAME}" "${SERVICE_PORT}"
}

#####################################################################

${scwryptsmodule}.select() {
	[ "${NAMESPACE}" ] || local NAMESPACE="$(kube.kubectl.namespace.get)"
	[ "${NAMESPACE}" ] || return 1

	local SERVICES="$(kube.kubectl.service.list)"
	local SELECTED="$({
		echo "namespace service port"
		echo ${SERVICES} \
			| jq -r '.service + " " + .port' \
			| sed "s/^/${NAMESPACE} /" \
			;
	} \
		| column -t \
		| utils.fzf 'select a service' --header-lines=1 \
		| awk '{print $2;}' \
	)"

	echo "${SERVICES}" | jq -c "select (.service == \"${SELECTED}\")"
}

${scwryptsmodule}.list() {
	kube.cli get service --no-headers\
		| awk '{print "{\"service\":\""$1"\",\"ip\":\""$3"\",\"port\":\""$5"\"}"}' \
		| jq -c 'select (.ip != "None")' \
		;
}

${scwryptsmodule}.get-password() {
	[ "${PASSWORD_SECRET}" ] && [ "${PASSWORD_KEY}" ] || return 0

	kube.cli get secret "${PASSWORD_SECRET}" -o jsonpath="{.data.${PASSWORD_KEY}}" \
		| base64 --decode
}

${scwryptsmodule}.parse() {
	SERVICE_NAME="$(echo "${SERVICE}" | jq -r .service)"
	SERVICE_PORT="$(echo "${SERVICE}" | jq -r .port | sed 's|/.*$||')"
}
