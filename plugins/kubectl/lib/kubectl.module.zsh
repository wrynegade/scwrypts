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

	[[ $CONTEXT =~ reset ]] && {
		: \
			&& REDIS del --prefix "current:context" \
			&& KUBECTL__SET_NAMESPACE reset \
			;
		return $?
	}

	: \
		&& REDIS set --prefix "current:context" "$CONTEXT" \
		&& KUBECTL__SET_NAMESPACE reset \
		;
}

KUBECTL__SELECT_CONTEXT() {
	KUBECTL__LIST_CONTEXTS | FZF 'select a context'
}

KUBECTL__LIST_CONTEXTS() {
	echo reset
	local ALL_CONTEXTS=$(KUBECTL config get-contexts -o name | sort)

	echo $ALL_CONTEXTS | grep -v '^arn:aws:eks'

	[[ $AWS_ACCOUNT ]] && {
		echo $ALL_CONTEXTS | grep "^arn:aws:eks:.*:$AWS_ACCOUNT"
		true
	} || {
		echo $ALL_CONTEXTS | grep '^arn:aws:eks'
	}
}

#####################################################################

KUBECTL__GET_NAMESPACE() { REDIS get --prefix "current:namespace"; }

KUBECTL__SET_NAMESPACE() {
	local NAMESPACE=$1
	[ ! $NAMESPACE ] && return 1

	[[ $NAMESPACE =~ reset ]] && {
		REDIS del --prefix "current:namespace"
		return $?
	}

	REDIS set --prefix "current:namespace" "$NAMESPACE"
}

KUBECTL__SELECT_NAMESPACE() {
	KUBECTL__LIST_NAMESPACES | FZF 'select a namespace'
}

KUBECTL__LIST_NAMESPACES() {
	echo reset
	echo default
	KUBECTL get namespaces -o name | sed 's/^namespace\///' | sort
}

#####################################################################

KUBECTL__SERVE() {
	[ $CONTEXT ] || local CONTEXT=$(KUBECTL__GET_CONTEXT)
	[ $CONTEXT ] || echo.error 'must configure a context in which to serve'

	[ $NAMESPACE ] || local NAMESPACE=$(KUBECTL__GET_NAMESPACE)
	[ $NAMESPACE ] || echo.error 'must configure a namespace in which to serve'

	CHECK_ERRORS --no-fail --no-usage || return 1

	[ $SERVICE ] && SERVICE=$(KUBECTL__LIST_SERVICES | jq -c "select (.service == \"$SERVICE\")" || echo $SERVICE)
	[ $SERVICE ] || local SERVICE=$(KUBECTL__SELECT_SERVICE)
	[ $SERVICE ] || echo.error 'must provide or select a service'

	KUBECTL__LIST_SERVICES | grep -q "^$SERVICE$"\
		|| echo.error "no service '$SERVICE' in '$CONFIG/$NAMESPACE'"

	CHECK_ERRORS --no-fail --no-usage || return 1

	##########################################

	SERVICE_PASSWORD="$(KUBECTL__GET_SERVICE_PASSWORD)"
	KUBECTL__SERVICE_PARSE

	echo.reminder "attempting to serve ${NAMESPACE}/${SERVICE_NAME}:${SERVICE_PORT}"
	[ $SERVICE_PASSWORD ] && echo.reminder "password : $SERVICE_PASSWORD"

	KUBECTL port-forward service/$SERVICE_NAME $SERVICE_PORT
}

KUBECTL__SELECT_SERVICE() {
	[ $NAMESPACE ] || local NAMESPACE=$(KUBECTL__GET_NAMESPACE)
	[ $NAMESPACE ] || return 1

	local SERVICES=$(KUBECTL__LIST_SERVICES)
	local SELECTED=$({
		echo "namespace service port"
		echo $SERVICES \
			| jq -r '.service + " " + .port' \
			| sed "s/^/$NAMESPACE /" \
			;
	} \
		| column -t \
		| FZF 'select a service' --header-lines=1 \
		| awk '{print $2;}' \
	)

	echo $SERVICES | jq -c "select (.service == \"$SELECTED\")"
}

KUBECTL__LIST_SERVICES() {
	KUBECTL get service --no-headers\
		| awk '{print "{\"service\":\""$1"\",\"ip\":\""$3"\",\"port\":\""$5"\"}"}' \
		| jq -c 'select (.ip != "None")' \
		;
}

KUBECTL__GET_SERVICE_PASSWORD() {
	[ $PASSWORD_SECRET ] && [ $PASSWORD_KEY ] || return 0

	KUBECTL get secret $PASSWORD_SECRET -o jsonpath="{.data.$PASSWORD_KEY}" \
		| base64 --decode
}

KUBECTL__SERVICE_PARSE() {
	SERVICE_NAME=$(echo $SERVICE | jq -r .service)
	SERVICE_PORT=$(echo $SERVICE | jq -r .port | sed 's|/.*$||')
}
