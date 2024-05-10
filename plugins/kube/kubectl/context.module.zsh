#####################################################################

use --group kube kubectl/cli
use --group kube kubectl/namespace
use --group kube redis

#####################################################################

${scwryptsmodule}.get() { kube.redis get --prefix "current:context"; }

${scwryptsmodule}.set() {
	local CONTEXT=$1
	[ ! "${CONTEXT}" ] && return 1

	[[ "${CONTEXT}" =~ reset ]] && {
		: \
			&& kube.redis del --prefix "current:context" \
			&& kube.kubectl.namespace.set reset \
			;
		return $?
	}

	: \
		&& kube.redis set --prefix "current:context" "${CONTEXT}" \
		&& kube.kubectl.namespace.set reset \
		;
}

${scwryptsmodule}.select() {
	case "$(kube.kubectl.context.list | grep -v '^reset$' | wc -l)" in
		( 0 )
			echo.error "no contexts available"
			return 1
			;;
		( 1 )
			kube.kubectl.context.list | tail -n1
			;;
		( * )
			kube.kubectl.context.list | utils.fzf 'select a context'
			;;
	esac
}

${scwryptsmodule}.list() {
	echo reset
	local ALL_CONTEXTS="$(kube.cli config get-contexts -o name | sort -u)"

	echo "${ALL_CONTEXTS}" | grep -v '^arn:aws:eks'

	[[ "${AWS_ACCOUNT}" ]] && {
		echo "${ALL_CONTEXTS}" | grep "^arn:aws:eks:.*:${AWS_ACCOUNT}"
		true
	} || {
		echo "${ALL_CONTEXTS}" | grep '^arn:aws:eks'
	}
}
