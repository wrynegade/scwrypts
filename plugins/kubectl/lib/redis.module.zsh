#####################################################################

DEPENDENCIES+=(
	redis-cli
	docker
)

REQUIRED_ENV+=()

__CHECK_ENV_VAR SCWRYPTS_KUBECTL_REDIS --default managed

#####################################################################

REDIS() {
	[ ! $USAGE ] && local USAGE="
		usage: [...options...]

		options:
		  --subsession [0-9]   use a particular subsession

		  -p, --prefix   apply dynamic prefix to the next command line argument

		  --get-prefix              output key prefix for current session+subsession
		  --get-static-definition   output the static ZSH function definition for REDIS

		  additional arguments and options are passed through to 'redis-cli'
	"

	local REDIS_ARGS=() USER_ARGS=()

	[ $SUBSESSION ] || local SUBSESSION=0

	local REDIS_PREFIX=$(eval echo '$SCWRYPTS_KUBECTL_REDIS_KEY_PREFIX__'$SCWRYPTS_KUBECTL_REDIS)
	[ $REDIS_PREFIX ] && REDIS_PREFIX+=':'

	while [[ $# -gt 0 ]]
	do
		case $1 in 
			-p | --prefix ) USER_ARGS+=("${REDIS_PREFIX}${SCWRYPTS_ENV}:${SUBSESSION}:$2"); shift 1 ;;

			--subsession            ) SUBSESSION=$2; shift 1 ;;

			--get-prefix            ) echo $REDIS_PREFIX; return 0 ;;
			--get-static-definition ) ECHO_STATIC_DEFINITION=1 ;;

			* ) USER_ARGS+=($1) ;;
		esac
		shift 1
	done

	local REDIS_HOST=$(eval echo '$SCWRYPTS_KUBECTL_REDIS_HOST__'$SCWRYPTS_KUBECTL_REDIS)
	local REDIS_PORT=$(eval echo '$SCWRYPTS_KUBECTL_REDIS_PORT__'$SCWRYPTS_KUBECTL_REDIS)
	local REDIS_AUTH=$(eval echo '$SCWRYPTS_KUBECTL_REDIS_AUTH__'$SCWRYPTS_KUBECTL_REDIS)

	[ $REDIS_HOST ] && REDIS_ARGS+=(-h $REDIS_HOST)
	[ $REDIS_PORT ] && REDIS_ARGS+=(-p $REDIS_PORT)
	[ $REDIS_AUTH ] && REDIS_ARGS+=(-a $REDIS_AUTH)

	REDIS_ARGS+=(--raw)

	[[ $ECHO_STATIC_DEFINITION -eq 1 ]] && {
		echo "REDIS() {\
			local USER_ARGS=(); \
			[ ! \$SUBSESSION ] && local SUBSESSION=0 ;\
			while [[ \$# -gt 0 ]]; \
			do \
				case \$1 in
				-p | --prefix ) USER_ARGS+=(\"${REDIS_PREFIX}\${SCWRYPTS_ENV}:\${SUBSESSION}:\$2\"); shift 1 ;; \
				* ) USER_ARGS+=(\$1) ;; \
				esac; \
				shift 1; \
			done; \
			redis-cli ${REDIS_ARGS[@]} \${USER_ARGS[@]}; \
		}" | sed 's/\s\+/ /g'
		return 0
	}

	redis-cli ${REDIS_ARGS[@]} ${USER_ARGS[@]}
}

REDIS ping | grep -qi pong || {
	RPID=$(docker ps -a | grep scwrypts-kubectl-redis | awk '{print $1;}')
	[ $RPID ] && STATUS 'refreshing redis instance' && docker rm -f $RPID
	unset RPID

	docker run \
		--detach \
		--name scwrypts-kubectl-redis \
		--publish $SCWRYPTS_KUBECTL_REDIS_PORT__managed:6379 \
		redis >/dev/null 2>&1

	STATUS 'awaiting redis connection'
	until REDIS ping 2>/dev/null | grep -qi pong; do sleep 0.5; done
}
