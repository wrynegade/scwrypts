#####################################################################

DEPENDENCIES+=(
	kubectl
)

REQUIRED_ENV+=()

use redis --group kubectl

#####################################################################

KUBECTL() {
	local NAMESPACE=$(REDIS get --prefix "current:namespace")
	local CONTEXT=$(KUBECTL__GET_CONTEXT)

	local KUBECTL_ARGS=()
	[ $NAMESPACE ] && KUBECTL_ARGS+=(--namespace $NAMESPACE)
	[ $CONTEXT   ] && KUBECTL_ARGS+=(--context $CONTEXT)

	kubectl ${KUBECTL_ARGS[@]} $@
}


#####################################################################

KUBECTL__GET_CONTEXT() { REDIS get --prefix "current:context"; }

KUBECTL__SET_CONTEXT() {
	local CONTEXT=$1
	[ ! $CONTEXT ] && return 1

	[[ $CONTEXT =~ default ]] && {
		: \
			&& REDIS del --prefix "current:context" \
			&& KUBECTL__SET_NAMESPACE default \
			;
		return $?
	}

	: \
		&& REDIS set --prefix "current:context" "$CONTEXT" \
		&& KUBECTL__SET_NAMESPACE default \
		;
}

KUBECTL__SELECT_CONTEXT() {
	KUBECTL__LIST_CONTEXTS | FZF 'select a context'
}

KUBECTL__LIST_CONTEXTS() {
	echo default
	KUBECTL config get-contexts -o name | sort
}

#####################################################################

KUBECTL__GET_NAMESPACE() { REDIS get --prefix "current:namespace"; }

KUBECTL__SET_NAMESPACE() {
	local NAMESPACE=$1
	[ ! $NAMESPACE ] && return 1

	[[ $NAMESPACE =~ default ]] && {
		REDIS del --prefix "current:namespace"
		return $?
	}

	REDIS set --prefix "current:namespace" "$NAMESPACE"
}

KUBECTL__SELECT_NAMESPACE() {
	KUBECTL__LIST_NAMESPACES | FZF 'select a namespace'
}

KUBECTL__LIST_NAMESPACES() {
	echo default
	KUBECTL get namespaces -o name | sed 's/^namespace\///' | sort
}
