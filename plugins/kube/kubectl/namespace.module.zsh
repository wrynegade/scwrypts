${scwryptsmodule}.get() { kube.redis get --prefix "current:namespace"; }

${scwryptsmodule}.set() {
	local NAMESPACE=$1
	[ ! "${NAMESPACE}" ] && return 1

	[[ "${NAMESPACE}" =~ reset ]] && {
		kube.redis del --prefix "current:namespace"
		return $?
	}

	kube.redis set --prefix "current:namespace" "${NAMESPACE}"
}

${scwryptsmodule}.select() {
	kube.kubectl.namespace.list | utils.fzf 'select a namespace'
}

${scwryptsmodule}.list() {
	echo reset
	echo default
	kube.cli get namespaces -o name | sed 's/^namespace\///' | sort | grep -v '^default$'
}
