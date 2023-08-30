#####################################################################
command -v compdef >/dev/null 2>&1 || return 0
#####################################################################

_k() {
	local C=$(k meta get context)
	local NS=$(k meta get namespace)

	local KUBEWORDS=(kubectl)
	[ $C  ] && KUBEWORDS+=(--context $C)
	[ $NS ] && KUBEWORDS+=(--namespace $NS)

	words="$KUBEWORDS ${words[@]:1}"
	_kubectl
}

compdef _k  k

#####################################################################
_h() {
	local C=$(k meta get context)
	local NS=$(k meta get namespace)

	local KUBEWORDS=(kubectl)
	[ $C  ] && KUBEWORDS+=(--context $C)
	[ $NS ] && KUBEWORDS+=(--namespace $NS)

	words="$KUBEWORDS ${words[@]:1}"
	_helm
}
compdef _h  h
