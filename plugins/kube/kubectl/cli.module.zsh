#####################################################################

DEPENDENCIES+=(kubectl)

use redis --group kube

#####################################################################

kube.cli() {
	local NAMESPACE="$(kube.redis get --prefix "current:namespace")"
	local CONTEXT="$(kube.kubectl.context.get)"

	local ARGS=()
	[ "${NAMESPACE}" ] && ARGS+=(--namespace "${NAMESPACE}")
	[ "${CONTEXT}"   ] && ARGS+=(--context "${CONTEXT}")

	kubectl ${ARGS[@]} $@
}
